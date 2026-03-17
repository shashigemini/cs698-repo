"""FastAPI application factory.

Creates and configures the application with all middleware,
routers, error handlers, and lifecycle management.
"""

from contextlib import asynccontextmanager

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
async def lifespan(app: FastAPI):
    """Manage application startup and shutdown.

    Initializes database and Redis connections on startup,
    and cleanly disposes them on shutdown.
    """
    settings = get_settings()
    setup_logging(debug=settings.debug)

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
        from app.models.user import User
        from sqlalchemy import select
        async for session in database.get_session():
            try:
                for uid, email in [("00000000-0000-0000-0000-000000000000", "guest@example.com"), ("11111111-1111-1111-1111-111111111111", "mock@example.com")]:
                    if not (await session.execute(select(User).where(User.id == uid))).scalar_one_or_none():
                        session.add(User(id=uid, email=email, password_hash="none", role="admin"))
                await session.commit()
                logger.info("Seeded backend debug users")
            except Exception as e:
                logger.error("Failed to seed debug users: %s", e)
            break


    # Initialize Qdrant Collection
    try:
        from qdrant_client import AsyncQdrantClient
        from qdrant_client.models import Distance, VectorParams
        
        qclient = AsyncQdrantClient(host=settings.qdrant_host, port=settings.qdrant_port)
        if not await qclient.collection_exists(settings.qdrant_collection):
            await qclient.create_collection(
                collection_name=settings.qdrant_collection,
                vectors_config=VectorParams(size=1536, distance=Distance.COSINE),
            )
            logger.info("Qdrant collection %s created", settings.qdrant_collection)
        else:
            logger.info("Qdrant collection %s already exists", settings.qdrant_collection)
    except Exception as e:
        logger.error("Failed to initialize Qdrant collection: %s", e)

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
        app.add_middleware(
            CSRFMiddleware, csrf_secret=settings.csrf_secret
        )

    # CORS — restricted to configured origins
    cors_kwargs = {
        "allow_origins": settings.cors_origins,
        "allow_credentials": True,
        "allow_methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": [
            "Authorization",
            "Content-Type",
            "X-CSRF-Token",
            "X-Request-ID",
        ],
        "expose_headers": ["X-Request-ID"],
    }
    if not settings.is_production:
        cors_kwargs["allow_origin_regex"] = r"^https?://(localhost|127\.0\.0\.1|host\.docker\.internal|.*github\.dev)(:[0-9]+)?$"
        cors_kwargs["allow_headers"] = ["*"]
        
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
    @app.get("/api/csrf")
    async def get_csrf_token(
        authorization: str = None,
    ):
        """Get a CSRF token bound to the current session."""
        import hashlib
        from app.middleware.csrf import generate_csrf_token

        if not authorization or not authorization.startswith("Bearer "):
            from fastapi import HTTPException
            raise HTTPException(401, "Authentication required")

        access_token = authorization[7:]
        session_id = hashlib.sha256(
            access_token.encode()
        ).hexdigest()[:32]

        token = generate_csrf_token(
            settings.csrf_secret, session_id
        )
        return {"csrf_token": token}

    # Health check with actual dependency status
    @app.get("/health/full")
    async def full_health_check():
        """Health check including dependency connectivity."""
        from datetime import datetime, timezone

        db_ok = await app.state.database.check_health()
        redis_ok = await app.state.redis.check_health()

        status = "healthy" if (db_ok and redis_ok) else "degraded"

        return {
            "status": status,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "version": settings.app_version,
            "environment": settings.environment,
            "services": {
                "database": "up" if db_ok else "down",
                "redis": "up" if redis_ok else "down",
                "qdrant": "unknown",
                "openai": "unknown",
            },
        }

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
