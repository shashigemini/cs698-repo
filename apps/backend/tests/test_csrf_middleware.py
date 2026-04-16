"""Tests for CSRF token generation, validation, and middleware."""

import hashlib
import time
from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import PlainTextResponse
from starlette.routing import Route

from app.middleware.csrf import (
    EXEMPT_PATHS,
    CSRFMiddleware,
    generate_csrf_token,
    validate_csrf_token,
)

SECRET = "test-csrf-secret"
SESSION_ID = "abc123session"


# --- Token Generation ---


class TestGenerateToken:
    """Tests for generate_csrf_token()."""

    def test_format(self):
        """Token is timestamp.hmac_hex format."""
        token = generate_csrf_token(SECRET, SESSION_ID)
        parts = token.split(".", 1)
        assert len(parts) == 2
        timestamp_str, signature = parts
        assert timestamp_str.isdigit()
        assert len(signature) == 64  # SHA-256 hex

    def test_deterministic_with_same_time(self):
        """Same inputs at same time produce same token."""
        with patch("app.middleware.csrf.time") as mock_time:
            mock_time.time.return_value = 1000000
            t1 = generate_csrf_token(SECRET, SESSION_ID)
            t2 = generate_csrf_token(SECRET, SESSION_ID)
        assert t1 == t2


# --- Token Validation ---


class TestValidateToken:
    """Tests for validate_csrf_token()."""

    def test_valid_token(self):
        """A freshly generated token validates."""
        token = generate_csrf_token(SECRET, SESSION_ID)
        assert validate_csrf_token(token, SECRET, SESSION_ID)

    def test_expired_token(self):
        """Token older than max_age is rejected."""
        with patch("app.middleware.csrf.time") as mock_time:
            mock_time.time.return_value = 1000000
            token = generate_csrf_token(SECRET, SESSION_ID)

        with patch("app.middleware.csrf.time") as mock_time:
            mock_time.time.return_value = 1000000 + 7200
            result = validate_csrf_token(
                token, SECRET, SESSION_ID, max_age_seconds=3600
            )
        assert result is False

    def test_wrong_session_id(self):
        """Token for a different session is rejected."""
        token = generate_csrf_token(SECRET, SESSION_ID)
        assert validate_csrf_token(
            token, SECRET, "wrong-session"
        ) is False

    def test_malformed_no_dot(self):
        """Token without a dot separator is rejected."""
        assert validate_csrf_token(
            "nodothere", SECRET, SESSION_ID
        ) is False

    def test_malformed_non_numeric_timestamp(self):
        """Token with non-numeric timestamp is rejected."""
        assert validate_csrf_token(
            "notanumber.abcdef", SECRET, SESSION_ID
        ) is False

    def test_tampered_signature(self):
        """Token with modified signature is rejected."""
        token = generate_csrf_token(SECRET, SESSION_ID)
        parts = token.split(".", 1)
        tampered = f"{parts[0]}.{'0' * 64}"
        assert validate_csrf_token(
            tampered, SECRET, SESSION_ID
        ) is False


# --- Middleware Dispatch ---


async def _ok_endpoint(request: Request) -> PlainTextResponse:
    return PlainTextResponse("OK")


def _make_csrf_app() -> Starlette:
    """Create a minimal app with CSRF middleware."""
    routes = [
        Route("/api/data", _ok_endpoint, methods=["GET", "POST"]),
        Route("/api/auth/login", _ok_endpoint, methods=["POST"]),
    ]
    app = Starlette(routes=routes)
    app.add_middleware(CSRFMiddleware, csrf_secret=SECRET)
    return app


def _make_bearer_and_csrf(access_token: str) -> dict:
    """Generate valid CSRF token + Authorization header."""
    session_id = hashlib.sha256(
        access_token.encode()
    ).hexdigest()[:32]
    csrf_token = generate_csrf_token(SECRET, session_id)
    return {
        "Authorization": f"Bearer {access_token}",
        "X-CSRF-Token": csrf_token,
    }


class TestCSRFMiddleware:
    """Integration tests for CSRFMiddleware.dispatch()."""

    @pytest.mark.asyncio
    async def test_get_skipped(self):
        """GET requests bypass CSRF check."""
        app = _make_csrf_app()
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            resp = await client.get("/api/data")
        assert resp.status_code == 200

    @pytest.mark.asyncio
    async def test_exempt_path_skipped(self):
        """Exempt paths (auth) bypass CSRF check."""
        app = _make_csrf_app()
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            resp = await client.post("/api/auth/login")
        assert resp.status_code == 200

    @pytest.mark.asyncio
    async def test_missing_token_403(self):
        """POST without X-CSRF-Token → 403 CSRF_MISSING."""
        app = _make_csrf_app()
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            resp = await client.post("/api/data")
        assert resp.status_code == 403
        assert resp.json()["error_code"] == "CSRF_MISSING"

    @pytest.mark.asyncio
    async def test_no_bearer_403(self):
        """POST with CSRF token but no Bearer → 403."""
        app = _make_csrf_app()
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            resp = await client.post(
                "/api/data",
                headers={"X-CSRF-Token": "fake.token"},
            )
        assert resp.status_code == 403
        assert resp.json()["error_code"] == "CSRF_INVALID"

    @pytest.mark.asyncio
    async def test_valid_csrf_passes(self):
        """POST with valid Bearer + matching CSRF → 200."""
        app = _make_csrf_app()
        headers = _make_bearer_and_csrf("my-access-token-123")
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            resp = await client.post(
                "/api/data", headers=headers
            )
        assert resp.status_code == 200

    @pytest.mark.asyncio
    async def test_invalid_csrf_rejected(self):
        """POST with Bearer but wrong CSRF token → 403."""
        app = _make_csrf_app()
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            resp = await client.post(
                "/api/data",
                headers={
                    "Authorization": "Bearer token123",
                    "X-CSRF-Token": "9999999.badbadbadbad",
                },
            )
        assert resp.status_code == 403
        assert resp.json()["error_code"] == "CSRF_INVALID"
