"""CSRF token validation middleware.

Validates a CSRF token on state-changing requests (POST, PUT, DELETE)
to protect against Cross-Site Request Forgery. The token is validated
via HMAC-SHA256 against the session's access token.

CSRF tokens are distributed via a separate /api/csrf endpoint and
must be sent in the X-CSRF-Token header on mutation requests.
"""

import hashlib
import hmac
import time
from typing import Optional

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app.core.logging import get_logger

logger = get_logger(__name__)

# Methods that require CSRF protection
PROTECTED_METHODS = {"POST", "PUT", "DELETE", "PATCH"}

# Paths exempt from CSRF (auth endpoints use rate limiting instead)
EXEMPT_PATHS = {
    "/api/auth/register",
    "/api/auth/login",
    "/api/auth/login/verify",
    "/api/auth/refresh",
    "/api/auth/recover",
    "/health",
    "/health/full",
    "/docs",
    "/redoc",
    "/openapi.json",
}


def generate_csrf_token(secret: str, session_id: str) -> str:
    """Generate a time-bound CSRF token.

    Args:
        secret: The CSRF secret from settings.
        session_id: User's access token jti or session identifier.

    Returns:
        CSRF token in format: timestamp.hmac_hex
    """
    timestamp = str(int(time.time()))
    payload = f"{timestamp}:{session_id}"
    signature = hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256,
    ).hexdigest()
    return f"{timestamp}.{signature}"


def validate_csrf_token(
    token: str,
    secret: str,
    session_id: str,
    max_age_seconds: int = 3600,
) -> bool:
    """Validate a CSRF token.

    Args:
        token: The token from X-CSRF-Token header.
        secret: The CSRF secret from settings.
        session_id: User's access token jti or session identifier.
        max_age_seconds: Maximum token age in seconds.

    Returns:
        True if the token is valid and not expired.
    """
    try:
        parts = token.split(".", 1)
        if len(parts) != 2:
            return False

        timestamp_str, received_sig = parts
        timestamp = int(timestamp_str)

        # Check expiry
        if time.time() - timestamp > max_age_seconds:
            return False

        # Recompute signature
        payload = f"{timestamp_str}:{session_id}"
        expected_sig = hmac.new(
            secret.encode(),
            payload.encode(),
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(received_sig, expected_sig)
    except (ValueError, UnicodeDecodeError):
        return False


class CSRFMiddleware(BaseHTTPMiddleware):
    """CSRF protection middleware.

    Validates X-CSRF-Token on state-changing requests.
    Exempt paths (auth, health) bypass validation.
    """

    def __init__(self, app, csrf_secret: str) -> None:
        super().__init__(app)
        self._secret = csrf_secret

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Skip non-mutation methods
        if request.method not in PROTECTED_METHODS:
            return await call_next(request)

        # Skip exempt paths
        if request.url.path in EXEMPT_PATHS:
            return await call_next(request)

        # Get CSRF token from header
        csrf_token = request.headers.get("X-CSRF-Token")
        if not csrf_token:
            return JSONResponse(
                status_code=403,
                content={
                    "error_code": "CSRF_MISSING",
                    "message": "Missing CSRF token",
                },
            )

        # Get session identifier from Authorization
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            # No auth → can't validate CSRF → reject
            return JSONResponse(
                status_code=403,
                content={
                    "error_code": "CSRF_INVALID",
                    "message": "CSRF validation failed",
                },
            )

        # Use a hash of the access token as session identifier
        access_token = auth_header[7:]
        session_id = hashlib.sha256(
            access_token.encode()
        ).hexdigest()[:32]

        if not validate_csrf_token(
            csrf_token, self._secret, session_id
        ):
            logger.warning("CSRF validation failed")
            return JSONResponse(
                status_code=403,
                content={
                    "error_code": "CSRF_INVALID",
                    "message": "CSRF validation failed",
                },
            )

        return await call_next(request)
