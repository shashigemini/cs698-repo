"""Auth Pydantic schemas — request and response models.

These are the wire-format contracts the frontend depends on.
"""

import base64
import re
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator


# --- Validators ---
_PASSWORD_MIN_LENGTH = 8
_PASSWORD_PATTERN = re.compile(
    r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$"
)


def _validate_password(v: str) -> str:
    """Enforce password complexity rules."""
    if len(v) < _PASSWORD_MIN_LENGTH:
        raise ValueError(
            f"Password must be at least {_PASSWORD_MIN_LENGTH} characters"
        )
    if not _PASSWORD_PATTERN.match(v):
        raise ValueError(
            "Password must include uppercase, lowercase, digit, "
            "and special character"
        )
    return v


# --- E2EE Registration (client sends derived keys, not raw password) ---


class RegisterRequest(BaseModel):
    """E2EE registration: client sends derived auth token + wrapped keys."""

    email: EmailStr = Field(max_length=255)
    client_auth_token: str = Field(
        min_length=1,
        description="Base64-encoded HKDF-derived auth token from LMK",
    )
    salt: str = Field(
        min_length=1,
        description="Base64-encoded Argon2id salt (16 bytes)",
    )
    wrapped_account_key: str = Field(
        min_length=1,
        description="Base64-encoded AES-GCM wrapped AccountKey",
    )
    recovery_wrapped_ak: str = Field(
        min_length=1,
        description="Base64-encoded RecoveryKey-wrapped AccountKey",
    )

    @field_validator("salt")
    @classmethod
    def validate_salt(cls, v: str) -> str:
        """Ensure salt is valid base64 and expected length."""
        try:
            decoded = base64.b64decode(v)
        except Exception:
            # Try URL-safe base64
            try:
                decoded = base64.urlsafe_b64decode(v)
            except Exception as e:
                raise ValueError("Salt must be valid base64") from e
        if len(decoded) < 8:
            raise ValueError("Salt must be at least 8 bytes")
        return v


# --- Login Challenge/Verify ---


class LoginChallengeRequest(BaseModel):
    """Step 1 of E2EE login: client sends email to get salt."""

    email: EmailStr = Field(max_length=255)


class LoginChallengeResponse(BaseModel):
    """Server returns the user's salt for key derivation."""

    salt: str = Field(description="Base64-encoded Argon2id salt")
    recovery_wrapped_ak: Optional[str] = Field(
        default=None,
        description="Base64-encoded RecoveryKey-wrapped AccountKey (used for recovery)",
    )


class LoginVerifyRequest(BaseModel):
    """Step 2: client sends derived auth token for verification."""

    email: EmailStr = Field(max_length=255)
    client_auth_token: str = Field(
        min_length=1,
        description="Base64-encoded HKDF-derived auth token from LMK",
    )


class LoginVerifyResponse(BaseModel):
    """Successful login returns JWT pair + wrapped AK."""

    user_id: str
    access_token: str
    refresh_token: str
    access_expires_at: datetime = Field(
        description="ISO 8601 datetime when the access token expires",
    )
    wrapped_account_key: str = Field(
        description="Client uses this to unwrap AK with LMK",
    )


# --- Auth Responses ---


class AuthResponse(BaseModel):
    """Response for registration (no wrapped AK return needed)."""

    user_id: str
    access_token: str
    refresh_token: str
    access_expires_at: datetime


# --- Token Refresh ---


class RefreshRequest(BaseModel):
    """Refresh token request (mobile sends in body, web via cookie)."""

    refresh_token: str = Field(min_length=1)


class RefreshResponse(BaseModel):
    """New token pair after refresh."""

    access_token: str
    refresh_token: str
    access_expires_at: datetime


# --- Password Change (E2EE) ---


class ChangePasswordRequest(BaseModel):
    """E2EE password change: client re-wraps AK with new LMK."""

    new_auth_token: str = Field(min_length=1)
    new_wrapped_account_key: str = Field(min_length=1)


# --- Account Recovery (E2EE) ---


class RecoverAccountRequest(BaseModel):
    """E2EE account recovery: client unwraps AK with RK, re-wraps with new LMK."""

    email: EmailStr = Field(max_length=255)
    new_auth_token: str = Field(min_length=1)
    new_wrapped_account_key: str = Field(min_length=1)


class RecoverAccountResponse(BaseModel):
    """Successful recovery auto-logs in and returns new tokens."""

    user_id: str
    access_token: str
    refresh_token: str
    access_expires_at: datetime
    wrapped_account_key: str
