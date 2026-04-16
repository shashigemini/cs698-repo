"""Tests for body size limit middleware."""

import pytest
from httpx import ASGITransport, AsyncClient
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import PlainTextResponse
from starlette.routing import Route

from app.middleware.body_limit import BodySizeLimitMiddleware


async def _echo(request: Request) -> PlainTextResponse:
    """Echo endpoint for testing."""
    body = await request.body()
    return PlainTextResponse(f"OK: {len(body)} bytes")


def _make_app(max_bytes: int = 1024) -> Starlette:
    """Create a minimal app with body limit middleware."""
    app = Starlette(routes=[Route("/echo", _echo, methods=["POST"])])
    app.add_middleware(BodySizeLimitMiddleware, max_bytes=max_bytes)
    return app


@pytest.mark.asyncio
async def test_rejects_oversized_content_length():
    """Requests with Content-Length exceeding the limit → 413."""
    app = _make_app(max_bytes=100)
    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.post(
            "/echo",
            content=b"x" * 200,
            headers={"content-length": "200"},
        )
    assert resp.status_code == 413
    data = resp.json()
    assert data["error_code"] == "PAYLOAD_TOO_LARGE"


@pytest.mark.asyncio
async def test_allows_within_limit():
    """Requests within the limit pass through."""
    app = _make_app(max_bytes=1024)
    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.post(
            "/echo",
            content=b"small payload",
            headers={"content-length": "13"},
        )
    assert resp.status_code == 200
    assert "OK" in resp.text


@pytest.mark.asyncio
async def test_allows_no_content_length():
    """Requests without Content-Length header pass through."""
    app = _make_app(max_bytes=100)
    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport, base_url="http://test"
    ) as client:
        resp = await client.post("/echo", content=b"")
    assert resp.status_code == 200
