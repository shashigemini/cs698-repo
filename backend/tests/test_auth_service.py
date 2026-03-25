"""Tests for the auth service — registration, login, and account management."""

import base64

import pytest
import pytest_asyncio

from app.core.exceptions import (
    AuthError,
    EmailExistsError,
    KeysNotFoundError,
)
from app.core.security import hash_password
from app.repositories.user_repo import UserRepository
from app.services.auth_service import AuthService


class TestAuthServiceRegister:
    """Tests for user registration."""

    @pytest.mark.asyncio
    async def test_register_success(self, db_session, test_settings):
        """Registration with valid data should return token pair."""
        auth = AuthService(test_settings, db_session)
        salt = base64.urlsafe_b64encode(b"\x00" * 16).decode()

        result = await auth.register(
            email="test@example.com",
            client_auth_token="dGVzdC1hdXRoLXRva2Vu",
            salt=salt,
            wrapped_account_key="wrapped-ak-base64",
            recovery_wrapped_ak="recovery-wrapped-ak-base64",
        )

        assert "user_id" in result
        assert "access_token" in result
        assert "refresh_token" in result
        assert "access_expires_at" in result

        # Verify user exists in DB
        repo = UserRepository(db_session)
        user = await repo.get_by_email("test@example.com")
        assert user is not None
        assert user.is_e2ee is True

        # Verify E2EE keys stored
        keys = await repo.get_e2ee_keys(user.id)
        assert keys is not None
        assert keys.wrapped_account_key == "wrapped-ak-base64"

    @pytest.mark.asyncio
    async def test_register_duplicate_email_raises(
        self, db_session, test_settings
    ):
        """Registering the same email twice should raise EmailExistsError."""
        auth = AuthService(test_settings, db_session)
        salt = base64.urlsafe_b64encode(b"\x01" * 16).decode()

        await auth.register(
            email="dup@example.com",
            client_auth_token="dGVzdDE=",
            salt=salt,
            wrapped_account_key="wak1",
            recovery_wrapped_ak="rwak1",
        )

        with pytest.raises(EmailExistsError):
            await auth.register(
                email="dup@example.com",
                client_auth_token="dGVzdDI=",
                salt=salt,
                wrapped_account_key="wak2",
                recovery_wrapped_ak="rwak2",
            )


class TestAuthServiceLogin:
    """Tests for the challenge-verify login flow."""

    @pytest_asyncio.fixture
    async def registered_user(self, db_session, test_settings):
        """Register a test user and return auth service + credentials."""
        auth = AuthService(test_settings, db_session)
        salt = base64.urlsafe_b64encode(b"\x02" * 16).decode()
        auth_token = "login-test-auth-token"

        result = await auth.register(
            email="login@example.com",
            client_auth_token=auth_token,
            salt=salt,
            wrapped_account_key="wrapped-key",
            recovery_wrapped_ak="recovery-key",
        )

        return {
            "auth": auth,
            "user_id": result["user_id"],
            "email": "login@example.com",
            "auth_token": auth_token,
            "salt": salt,
        }

    @pytest.mark.asyncio
    async def test_login_challenge_returns_salt(
        self, registered_user
    ):
        """Login challenge should return the user's salt."""
        auth = registered_user["auth"]
        result = await auth.login_challenge(
            email=registered_user["email"]
        )

        assert "salt" in result
        # Should be valid base64
        decoded = base64.urlsafe_b64decode(result["salt"])
        assert len(decoded) >= 8

    @pytest.mark.asyncio
    async def test_login_challenge_nonexistent_returns_fake_salt(
        self, db_session, test_settings
    ):
        """Challenge for nonexistent user should return a fake salt
        (anti-enumeration)."""
        auth = AuthService(test_settings, db_session)
        result = await auth.login_challenge(
            email="nobody@example.com"
        )

        assert "salt" in result
        # Should still be valid base64
        decoded = base64.urlsafe_b64decode(result["salt"])
        assert len(decoded) > 0

    @pytest.mark.asyncio
    async def test_login_verify_correct_token(
        self, registered_user
    ):
        """Verify with correct auth token should return tokens + wrapped AK."""
        auth = registered_user["auth"]
        result = await auth.login_verify(
            email=registered_user["email"],
            client_auth_token=registered_user["auth_token"],
        )

        assert result["user_id"] == registered_user["user_id"]
        assert "access_token" in result
        assert "refresh_token" in result
        assert result["wrapped_account_key"] == "wrapped-key"

    @pytest.mark.asyncio
    async def test_login_verify_wrong_token_raises(
        self, registered_user
    ):
        """Verify with wrong auth token should raise AuthError."""
        auth = registered_user["auth"]

        with pytest.raises(AuthError):
            await auth.login_verify(
                email=registered_user["email"],
                client_auth_token="wrong-token",
            )

    @pytest.mark.asyncio
    async def test_login_verify_nonexistent_email_raises(
        self, db_session, test_settings
    ):
        """Verify for nonexistent email should raise AuthError."""
        auth = AuthService(test_settings, db_session)

        with pytest.raises(AuthError):
            await auth.login_verify(
                email="ghost@example.com",
                client_auth_token="any-token",
            )


class TestAuthServiceAccountManagement:
    """Tests for password change, recovery, and deletion."""

    @pytest_asyncio.fixture
    async def setup_user(self, db_session, test_settings):
        """Create a test user and return context."""
        auth = AuthService(test_settings, db_session)
        salt = base64.urlsafe_b64encode(b"\x03" * 16).decode()

        result = await auth.register(
            email="manage@example.com",
            client_auth_token="original-token",
            salt=salt,
            wrapped_account_key="original-wak",
            recovery_wrapped_ak="original-rwak",
        )
        await db_session.commit()

        return {
            "auth": auth,
            "user_id": result["user_id"],
            "email": "manage@example.com",
        }

    @pytest.mark.asyncio
    async def test_change_password(self, setup_user):
        """Password change should update auth hash and wrapped AK."""
        auth = setup_user["auth"]

        await auth.change_password(
            user_id=setup_user["user_id"],
            new_auth_token="new-auth-token",
            new_wrapped_account_key="new-wak",
        )

        # Verify new credentials work
        result = await auth.login_verify(
            email=setup_user["email"],
            client_auth_token="new-auth-token",
        )
        assert result["wrapped_account_key"] == "new-wak"

    @pytest.mark.asyncio
    async def test_delete_account(self, setup_user, db_session):
        """Account deletion should remove user and all data."""
        auth = setup_user["auth"]

        deleted = await auth.delete_account(
            user_id=setup_user["user_id"]
        )
        assert deleted is True

        # Verify user is gone
        repo = UserRepository(db_session)
        user = await repo.get_by_email(setup_user["email"])
        assert user is None
