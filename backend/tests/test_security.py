"""Tests for core.security — password hashing and JWT operations."""

import time
from datetime import datetime, timezone

import pytest

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)


class TestPasswordHashing:
    """Tests for Argon2id password hashing."""

    def test_hash_and_verify_correct(self, test_settings):
        """A correct password should verify against its hash."""
        password = "MyS3cur3P@ssw0rd!"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_verify_wrong_password(self, test_settings):
        """A wrong password should not verify."""
        hashed = hash_password("correct-password")

        assert verify_password("wrong-password", hashed) is False

    def test_hash_is_different_each_time(self, test_settings):
        """Two hashes of the same password should differ (unique salt)."""
        password = "same-password"
        h1 = hash_password(password)
        h2 = hash_password(password)

        assert h1 != h2

    def test_hash_starts_with_argon2id(self, test_settings):
        """The hash format should be Argon2id."""
        hashed = hash_password("test")
        assert hashed.startswith("$argon2id$")


class TestJWT:
    """Tests for JWT creation and validation."""

    def test_create_and_decode_access_token(self, test_settings):
        """Access token should decode with correct claims."""
        token, expires_at = create_access_token(
            test_settings,
            user_id="user-123",
            role="user",
        )

        payload = decode_token(
            test_settings, token, expected_type="access"
        )

        assert payload["sub"] == "user-123"
        assert payload["role"] == "user"
        assert payload["type"] == "access"
        assert "jti" in payload
        assert isinstance(expires_at, datetime)

    def test_create_and_decode_refresh_token(self, test_settings):
        """Refresh token should decode with correct claims."""
        token, expires_at, jti = create_refresh_token(
            test_settings,
            user_id="user-456",
        )

        payload = decode_token(
            test_settings, token, expected_type="refresh"
        )

        assert payload["sub"] == "user-456"
        assert payload["type"] == "refresh"
        assert payload["jti"] == jti

    def test_decode_wrong_type_raises(self, test_settings):
        """Decoding with wrong expected_type should raise."""
        from app.core.exceptions import TokenError

        token, _ = create_access_token(
            test_settings,
            user_id="user-123",
            role="user",
        )

        with pytest.raises(TokenError):
            decode_token(
                test_settings, token, expected_type="refresh"
            )

    def test_decode_invalid_token_raises(self, test_settings):
        """A garbage token should raise TokenError."""
        from app.core.exceptions import TokenError

        with pytest.raises(TokenError):
            decode_token(
                test_settings, "not-a-valid-jwt", expected_type="access"
            )

    def test_access_token_has_jti(self, test_settings):
        """Every access token should have a unique jti."""
        t1, _ = create_access_token(
            test_settings, user_id="u1", role="user"
        )
        t2, _ = create_access_token(
            test_settings, user_id="u1", role="user"
        )

        p1 = decode_token(test_settings, t1, expected_type="access")
        p2 = decode_token(test_settings, t2, expected_type="access")

        assert p1["jti"] != p2["jti"]
