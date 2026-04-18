"""Security utilities: password hashing, JWT, and CSRF.

Argon2id for password/auth-token hashing.
RS256 JWTs with configurable key pair.
CSRF token generation via secrets module.
"""

import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from jose import JWTError, jwt

from app.config import Settings
from app.core.exceptions import TokenError

# Argon2id context
_ph = PasswordHasher(
    memory_cost=65536,  # 64 MB
    time_cost=3,
    parallelism=1,
)


def hash_password(password: str) -> str:
    """Hash a password (or ClientAuthToken) with Argon2id."""
    return _ph.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    """Verify password (or ClientAuthToken) against stored hash.

    Uses constant-time comparison internally via argon2-cffi.
    """
    try:
        return _ph.verify(hashed, plain)
    except VerifyMismatchError:
        return False


def create_access_token(
    settings: Settings,
    *,
    user_id: str,
    role: str = "user",
    extra_claims: Optional[dict[str, Any]] = None,
) -> tuple[str, datetime]:
    """Generate a signed JWT access token.

    Returns:
        Tuple of (encoded_token, expiry_datetime).
    """
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=settings.jwt_access_token_ttl_minutes)
    jti = str(uuid.uuid4())

    payload = {
        "sub": user_id,
        "role": role,
        "type": "access",
        "jti": jti,
        "iat": now,
        "exp": expires_at,
        **(extra_claims or {}),
    }

    token = jwt.encode(
        payload,
        settings.jwt_private_key,
        algorithm=settings.jwt_algorithm,
    )
    return token, expires_at


def create_refresh_token(
    settings: Settings,
    *,
    user_id: str,
) -> tuple[str, datetime, str]:
    """Generate a signed JWT refresh token.

    Returns:
        Tuple of (encoded_token, expiry_datetime, jti).
    """
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(days=settings.jwt_refresh_token_ttl_days)
    jti = str(uuid.uuid4())

    payload = {
        "sub": user_id,
        "type": "refresh",
        "jti": jti,
        "iat": now,
        "exp": expires_at,
    }

    token = jwt.encode(
        payload,
        settings.jwt_private_key,
        algorithm=settings.jwt_algorithm,
    )
    return token, expires_at, jti


def decode_token(
    settings: Settings,
    token: str,
    *,
    expected_type: str = "access",
) -> dict[str, Any]:
    """Decode and validate a JWT.

    Raises:
        TokenError: If the token is invalid, expired, or wrong type.
    """
    import logging

    logger = logging.getLogger(__name__)
    try:
        payload = jwt.decode(
            token,
            settings.jwt_public_key,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError as e:
        logger.error(
            "JWT Validation Error: %s, Token: %s..., Alg: %s",
            e,
            token[:20],
            settings.jwt_algorithm,
        )
        raise TokenError(f"Invalid token: {e}") from e

    if payload.get("type") != expected_type:
        logger.error(
            f"Token type mismatch: expected {expected_type}, got {payload.get('type')}"
        )
        raise TokenError(f"Expected {expected_type} token, got {payload.get('type')}")

    return payload


def generate_csrf_token() -> str:
    """Generate a cryptographically secure CSRF token."""
    return secrets.token_urlsafe(32)
