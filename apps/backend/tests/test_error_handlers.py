"""Tests for global error handlers."""

import pytest
from fastapi import FastAPI, Request
from fastapi.routing import APIRoute
from httpx import ASGITransport, AsyncClient

from app.core.error_handlers import register_error_handlers
from app.core.exceptions import (
    AuthError,
    ForbiddenError,
    NotFoundError,
    RateLimitError,
    ValidationError,
)


def _make_app() -> FastAPI:
    """Create a minimal app with error handlers registered."""
    app = FastAPI()
    register_error_handlers(app)

    @app.get("/raise-auth")
    async def raise_auth():
        raise AuthError("Bad credentials")

    @app.get("/raise-notfound")
    async def raise_not_found():
        raise NotFoundError("Item missing")

    @app.get("/raise-forbidden")
    async def raise_forbidden():
        raise ForbiddenError("Access denied")

    @app.get("/raise-ratelimit")
    async def raise_rate_limit():
        raise RateLimitError("Too many requests")

    @app.get("/raise-validation")
    async def raise_validation():
        raise ValidationError("Bad input", details={"field": "email"})

    @app.get("/raise-unhandled")
    async def raise_unhandled():
        raise RuntimeError("something broke internally")

    @app.post("/validated")
    async def validated(request: Request):
        from pydantic import BaseModel, Field

        class Body(BaseModel):
            email: str = Field(min_length=5)

        body = Body(**(await request.json()))
        return {"email": body.email}

    return app


@pytest.fixture
def error_app():
    return _make_app()


@pytest.mark.asyncio
async def test_authentication_error(error_app):
    """AuthenticationError → 401 with error envelope."""
    transport = ASGITransport(app=error_app, raise_app_exceptions=False)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.get("/raise-auth")
    assert resp.status_code == 401
    data = resp.json()
    assert data["error_code"] == "INVALID_CREDENTIALS"
    assert "Bad credentials" in data["message"]


@pytest.mark.asyncio
async def test_not_found_error(error_app):
    """NotFoundError → 404."""
    transport = ASGITransport(app=error_app, raise_app_exceptions=False)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.get("/raise-notfound")
    assert resp.status_code == 404
    assert resp.json()["error_code"] == "CONVERSATION_NOT_FOUND"


@pytest.mark.asyncio
async def test_forbidden_error(error_app):
    """ForbiddenError → 403."""
    transport = ASGITransport(app=error_app, raise_app_exceptions=False)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.get("/raise-forbidden")
    assert resp.status_code == 403
    assert resp.json()["error_code"] == "FORBIDDEN"


@pytest.mark.asyncio
async def test_rate_limit_error(error_app):
    """RateLimitError → 429."""
    transport = ASGITransport(app=error_app, raise_app_exceptions=False)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.get("/raise-ratelimit")
    assert resp.status_code == 429
    assert resp.json()["error_code"] == "RATE_LIMIT_EXCEEDED"


@pytest.mark.asyncio
async def test_validation_error_with_details(error_app):
    """ValidationError → 400 with details dict."""
    transport = ASGITransport(app=error_app, raise_app_exceptions=False)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.get("/raise-validation")
    assert resp.status_code == 400
    data = resp.json()
    assert data["error_code"] == "VALIDATION_ERROR"
    assert data["details"]["field"] == "email"


@pytest.mark.asyncio
async def test_unhandled_exception(error_app):
    """Unhandled exceptions → 500 INTERNAL_ERROR (no leak)."""
    transport = ASGITransport(app=error_app, raise_app_exceptions=False)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.get("/raise-unhandled")
    assert resp.status_code == 500
    data = resp.json()
    assert data["error_code"] == "INTERNAL_ERROR"
    assert "something broke" not in data["message"]
    assert data["details"] is None
