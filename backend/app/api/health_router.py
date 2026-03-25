"""Health router — /health endpoint.

Reports system health and dependency status.
"""

from datetime import datetime, timezone

from fastapi import APIRouter

from app.config import get_settings
from app.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check() -> dict:
    """Return application health and dependency status.

    Note: Database and Redis checks are injected at the main
    app level to avoid circular imports. This base handler
    returns the app-level health; the full check is wired
    in main.py.
    """
    settings = get_settings()
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": settings.app_version,
        "environment": settings.environment,
        "services": {
            "database": "unknown",
            "redis": "unknown",
            "qdrant": "unknown",
            "openai": "unknown",
        },
    }
