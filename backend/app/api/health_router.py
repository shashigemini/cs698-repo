"""Application liveness and readiness endpoints."""

from datetime import datetime, timezone

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from openai import AsyncOpenAI

from app.config import get_settings
from app.core.logging import get_logger
from app.rag.retriever import Retriever

logger = get_logger(__name__)

router = APIRouter(tags=["Health"])


@router.get("/health")
async def liveness_check() -> dict:
    """Lightweight liveness endpoint for process/container checks."""
    settings = get_settings()
    return {
        "status": "alive",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": settings.app_version,
        "environment": settings.environment,
    }


async def _check_openai(settings) -> bool:
    """Check OpenAI dependency using a low-cost API call."""
    if settings.environment in {"testing", "e2e_testing"} or settings.openai_api_key in {"e2e-mock-key", "test-key"}:
        return True
    if not settings.openai_api_key:
        return False

    try:
        client = AsyncOpenAI(api_key=settings.openai_api_key, timeout=settings.openai_timeout_seconds)
        await client.models.list()
        return True
    except Exception as exc:
        logger.warning("OpenAI readiness check failed: %s", exc)
        return False


@router.get("/health/full")
async def readiness_check(request: Request) -> dict:
    """Readiness endpoint validating core dependencies for RAG usage."""
    settings = get_settings()

    db_ok = await request.app.state.database.check_health()
    redis_ok = await request.app.state.redis.check_health()
    qdrant_ok = await Retriever(settings).check_health()
    openai_ok = await _check_openai(settings)

    all_ok = db_ok and redis_ok and qdrant_ok and openai_ok

    payload = {
        "status": "healthy" if all_ok else "degraded",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": settings.app_version,
        "environment": settings.environment,
        "services": {
            "database": "up" if db_ok else "down",
            "redis": "up" if redis_ok else "down",
            "qdrant": "up" if qdrant_ok else "down",
            "openai": "up" if openai_ok else "down",
        },
    }

    if all_ok:
        return payload
    return JSONResponse(status_code=503, content=payload)
