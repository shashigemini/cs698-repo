"""FastAPI application factory.

Creates and configures the application with all middleware,
routers, error handlers, and lifecycle management.
"""

import typing
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.admin_router import router as admin_router
from app.api.auth_router import router as auth_router
from app.api.chat_router import router as chat_router
from app.api.health_router import router as health_router
from app.config import get_settings
from app.core.database import Database
from app.core.error_handlers import register_error_handlers
from app.core.logging import get_logger, setup_logging
from app.core.redis import RedisClient
from app.dependencies import set_database, set_redis
from app.middleware.body_limit import BodySizeLimitMiddleware
from app.middleware.csrf import CSRFMiddleware
from app.middleware.request_id import RequestIDMiddleware
from app.middleware.security_headers import SecurityHeadersMiddleware

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> typing.AsyncGenerator[None, None]:
    """Manage application startup and shutdown.

    Initializes database and Redis connections on startup,
    and cleanly disposes them on shutdown.
    """
    settings = get_settings()
    setup_logging(debug=settings.debug, structured=settings.is_production)

    logger.info(
        "Starting %s v%s (%s), DEBUG: %s",
        settings.app_name,
        settings.app_version,
        settings.environment,
        settings.debug,
    )

    # Initialize database
    database = Database(settings)
    set_database(database)
    logger.info("Database connection pool initialized")

    # Initialize Redis
    redis_client = RedisClient(settings)
    set_redis(redis_client)
    logger.info("Redis connection pool initialized")

    # Store on app state for health checks
    app.state.database = database
    app.state.redis = redis_client

    if settings.debug:
        from sqlalchemy import select

        from app.models.user import User

        async for session in database.get_session():
            try:
                for uid, email in [
                    ("00000000-0000-0000-0000-000000000000", "guest@example.com"),
                    ("11111111-1111-1111-1111-111111111111", "mock@example.com"),
                ]:
                    if not (
                        await session.execute(select(User).where(User.id == uid))
                    ).scalar_one_or_none():
                        session.add(
                            User(
                                id=uid, email=email, password_hash="none", role="admin"
                            )
                        )
                await session.commit()
                logger.info("Seeded backend debug users")
            except Exception as e:
                logger.error("Failed to seed debug users: %s", e)
            break

    # Initialize Qdrant Collection (with readiness retry)
    import asyncio

    from qdrant_client import AsyncQdrantClient
    from qdrant_client.models import Distance, VectorParams

    logger.info(
        "Initializing Qdrant client at %s:%s",
        settings.qdrant_host,
        settings.qdrant_port,
    )
    qclient = AsyncQdrantClient(
        host=settings.qdrant_host,
        port=settings.qdrant_port,
        check_compatibility=False,
    )

    _max_attempts = 10
    _retry_delay = 2.0
    for _attempt in range(1, _max_attempts + 1):
        try:
            exists = await qclient.collection_exists(settings.qdrant_collection)
            if not exists:
                logger.info(
                    "Creating Qdrant collection: %s", settings.qdrant_collection
                )
                await qclient.create_collection(
                    collection_name=settings.qdrant_collection,
                    vectors_config=VectorParams(size=1536, distance=Distance.COSINE),
                )
                logger.info(
                    "Successfully created Qdrant collection: %s",
                    settings.qdrant_collection,
                )
            else:
                logger.info(
                    "Qdrant collection '%s' already exists",
                    settings.qdrant_collection,
                )
            app.state.qdrant = qclient
            break
        except Exception as e:
            if _attempt == _max_attempts:
                logger.error(
                    "Qdrant not available after %d attempts — "
                    "document search will be unavailable: %s",
                    _max_attempts,
                    e,
                )
                app.state.qdrant = None
            else:
                logger.warning(
                    "Qdrant not ready (attempt %d/%d): %s — retrying in %.0fs",
                    _attempt,
                    _max_attempts,
                    e,
                    _retry_delay,
                )
                await asyncio.sleep(_retry_delay)

    # Start token cleanup background task
    from app.services.token_cleanup import TokenCleanupTask

    cleanup_task = TokenCleanupTask(interval_hours=24)
    cleanup_task.start()

    yield

    # Shutdown
    await cleanup_task.stop()
    await database.close()
    await redis_client.close()
    logger.info("Application shutdown complete")


def create_app() -> FastAPI:
    """Build the FastAPI application with full middleware and routing."""
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        lifespan=lifespan,
    )

    # --- Middleware stack (order matters: outermost runs first) ---

    # Diagnostic logging for preflight/400 errors
    @app.middleware("http")
    async def diagnostic_middleware(request, call_next):
        response = await call_next(request)
        if response.status_code == 400:
            logger.warning(
                "400 Bad Request on %s %s. Origin: %s, Host: %s, UA: %s",
                request.method,
                request.url.path,
                request.headers.get("Origin"),
                request.headers.get("Host"),
                request.headers.get("User-Agent"),
            )
        return response

    # Security headers on every response
    app.add_middleware(SecurityHeadersMiddleware)

    # Request ID for tracing
    app.add_middleware(RequestIDMiddleware)

    # Body size limit (reject >1MB before reading body)
    app.add_middleware(
        BodySizeLimitMiddleware,
        max_bytes=settings.max_request_body_bytes,
    )

    # CSRF protection on mutation requests
    if settings.is_production:
        app.add_middleware(CSRFMiddleware, csrf_secret=settings.csrf_secret)

    # CORS — restricted to configured origins
    logger.info("Configured CORS origins: %s", settings.cors_origins)
    cors_kwargs: dict[str, typing.Any] = {
        "allow_origins": settings.cors_origins,
        "allow_credentials": True,
        "allow_methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": [
            "*"
        ],  # Allow all headers in production to prevent preflight blocks
        "expose_headers": ["X-Request-ID"],
    }

    # Always allow Amplify subdomains and localhost/dev environments
    cors_kwargs["allow_origin_regex"] = (
        r"^https?://(localhost|127\.0\.0\.1|.*\.amplifyapp\.com|.*\.cloudfront\.net|.*github\.dev)(:[0-9]+)?$"
    )

    app.add_middleware(CORSMiddleware, **cors_kwargs)

    # --- Error handlers ---
    register_error_handlers(app)

    # --- Routers ---
    app.include_router(auth_router)
    app.include_router(chat_router)
    app.include_router(admin_router)
    app.include_router(health_router)

    # E2E test router
    if settings.environment == "e2e_testing":
        from app.api.test_router import router as test_router

        app.include_router(test_router)

    # --- CSRF Token Endpoint ---
    from fastapi import Header as _Header

    @app.get("/api/csrf")
    async def get_csrf_token(
        authorization: Optional[str] = _Header(default=None),
    ):
        """Get a CSRF token bound to the current session."""
        import hashlib

        from app.middleware.csrf import generate_csrf_token

        if not authorization or not authorization.startswith("Bearer "):
            from fastapi import HTTPException

            raise HTTPException(401, "Authentication required")

        access_token = authorization[7:]
        session_id = hashlib.sha256(access_token.encode()).hexdigest()[:32]

        token = generate_csrf_token(settings.csrf_secret, session_id)
        return {"csrf_token": token}

    return app


def get_e2e_app() -> FastAPI:
    """Entry point for E2E backend that patches dependencies."""
    app = create_app()
    # Apply monkey patches to replace OpenAI with stubs
    from app.e2e_overrides import apply_e2e_overrides

    apply_e2e_overrides(app)
    return app


# Uvicorn entry point
import os

if os.getenv("ENVIRONMENT") == "e2e_testing":
    app = get_e2e_app()
else:
    app = create_app()
