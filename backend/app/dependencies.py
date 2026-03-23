"""FastAPI dependency injection definitions.

Provides database sessions, authenticated user extraction,
and service instances to route handlers via Depends().
"""

from typing import Annotated, AsyncGenerator, Optional

from fastapi import Depends, Header, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.core.database import Database
from app.core.exceptions import ForbiddenError, TokenError
from app.core.redis import RedisClient
from app.services.auth_service import AuthService
from app.services.rate_limiter import RateLimiter
from app.services.token_service import TokenService

# These will be set during app startup (lifespan)
_database: Optional[Database] = None
_redis: Optional[RedisClient] = None


def set_database(db: Database) -> None:
    """Set the global database instance (called during app startup)."""
    global _database
    _database = db


def set_redis(redis: RedisClient) -> None:
    """Set the global Redis instance (called during app startup)."""
    global _redis
    _redis = redis


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield a database session for a single request."""
    if _database is None:
        raise RuntimeError("Database not initialized")
    async for session in _database.get_session():
        yield session


async def get_redis():
    """Get the Redis client instance."""
    if _redis is None:
        raise RuntimeError("Redis not initialized")
    return _redis.client


def get_rate_limiter(
    redis=Depends(get_redis),
    settings: Settings = Depends(get_settings),
) -> RateLimiter:
    """Provide a RateLimiter instance."""
    return RateLimiter(redis, settings)


def get_token_service(
    settings: Settings = Depends(get_settings),
    session: AsyncSession = Depends(get_db),
) -> TokenService:
    """Provide a TokenService instance."""
    return TokenService(settings, session)


def get_auth_service(
    settings: Settings = Depends(get_settings),
    session: AsyncSession = Depends(get_db),
) -> AuthService:
    """Provide an AuthService instance."""
    return AuthService(settings, session)


async def get_current_user(
    request: Request,
    token_service: TokenService = Depends(get_token_service),
    authorization: Optional[str] = Header(None),
    settings: Settings = Depends(get_settings),
) -> dict:
    """Extract and validate the current user from the Authorization header.

    In debug mode, if no token is provided, a dummy demo user is returned.
    """
    if settings.debug:
        if authorization == "Bearer mock-access-token":
             return {"sub": "11111111-1111-1111-1111-111111111111", "role": "admin"}
             
    if authorization is None or not authorization.startswith("Bearer "):
        raise TokenError("Missing or invalid Authorization header")

    token = str(authorization).removeprefix("Bearer ")
    return token_service.validate_access_token(token)


async def get_optional_user(
    token_service: TokenService = Depends(get_token_service),
    authorization: Optional[str] = Header(None),
    settings: Settings = Depends(get_settings),
) -> Optional[dict]:
    """Extract user if present, return None for guests.

    Does NOT raise on missing/invalid token — used for
    endpoints that support both guest and authenticated access.
    """
    if settings.debug and authorization == "Bearer mock-access-token":
        return {"sub": "11111111-1111-1111-1111-111111111111", "role": "admin"}
    if authorization is None or not authorization.startswith("Bearer "):
        return None

    token = str(authorization).removeprefix("Bearer ")
    try:
        return token_service.validate_access_token(token)
    except TokenError:
        return None


async def require_admin(
    user: dict = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
) -> dict:
    """Require the authenticated user to have admin role.

    In development/debug mode, any authenticated user is treated as an admin.
    """
    if settings.debug and user.get("sub") == "11111111-1111-1111-1111-111111111111":
        return user
        
    if user.get("role") != "admin":
        raise ForbiddenError(
            details={"required_role": "admin"}
        )
    return user


def get_client_ip(request: Request) -> str:
    """Extract client IP, respecting X-Forwarded-For if behind a proxy."""
    x_forwarded_for = request.headers.get("X-Forwarded-For")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.client.host if request.client else "127.0.0.1"

# Type aliases for cleaner route signatures
DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[dict, Depends(get_current_user)]
OptionalUser = Annotated[Optional[dict], Depends(get_optional_user)]
AdminUser = Annotated[dict, Depends(require_admin)]
AuthSvc = Annotated[AuthService, Depends(get_auth_service)]
TokenSvc = Annotated[TokenService, Depends(get_token_service)]
RateLimitSvc = Annotated[RateLimiter, Depends(get_rate_limiter)]
ClientIP = Annotated[str, Depends(get_client_ip)]
