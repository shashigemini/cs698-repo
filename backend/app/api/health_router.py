"""Health router — /health endpoint.

Reports system health and dependency status.
"""

from collections.abc import Awaitable, Callable
from datetime import datetime, timezone

from fastapi import APIRouter, Request

from app.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter(tags=["Health"])


async def _run_check(
    checker: Callable[[], Awaitable[bool]] | None,
) -> bool | None:
    """Execute a health check coroutine when configured."""
    if checker is None:
        return None

    try:
        return await checker()
    except Exception as exc:
        logger.warning("Health check failed: %s", exc)
        return False


def _status_label(result: bool | None) -> str:
    """Convert a boolean health result into a service label."""
    if result is None:
        return "unknown"
    return "up" if result else "down"


async def _build_health_payload(request: Request) -> dict:
    """Collect dependency-aware health information from app state."""
    settings = get_settings()
    database = getattr(request.app.state, "database", None)
    redis = getattr(request.app.state, "redis", None)
    qdrant_checker = getattr(request.app.state, "qdrant_health_check", None)
    openai_checker = getattr(request.app.state, "openai_health_check", None)

    db_ok = await _run_check(getattr(database, "check_health", None))
    redis_ok = await _run_check(getattr(redis, "check_health", None))
    qdrant_ok = await _run_check(qdrant_checker)
    openai_ok = await _run_check(openai_checker)

    dependency_results = [db_ok, redis_ok, qdrant_ok, openai_ok]
    known_results = [result for result in dependency_results if result is not None]
    status = "healthy" if known_results and all(known_results) else "degraded"

    return {
        "status": status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": settings.app_version,
        "environment": settings.environment,
        "services": {
            "database": _status_label(db_ok),
            "redis": _status_label(redis_ok),
            "qdrant": _status_label(qdrant_ok),
            "openai": _status_label(openai_ok),
        },
    }


@router.get("/health")
async def health_check(request: Request) -> dict:
    """Return dependency-aware application health."""
    return await _build_health_payload(request)
