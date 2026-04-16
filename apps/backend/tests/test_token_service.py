"""Tests for TokenService — JWT generation, validation, revocation, rotation."""

import uuid
from datetime import datetime, timedelta, timezone

import pytest
import pytest_asyncio

from app.models.user import User
from app.repositories.revoked_token_repo import RevokedTokenRepository
from app.services.token_service import TokenService


@pytest_asyncio.fixture
async def user(db_session):
    """Create a test user."""
    u = User(
        email="token-test@example.com",
        password_hash="argon2$fake",
        role="user",
    )
    db_session.add(u)
    await db_session.flush()
    return u


@pytest.fixture
def token_service(db_session, test_settings):
    """Provide a TokenService with test settings."""
    return TokenService(
        settings=test_settings,
        session=db_session,
    )


class TestTokenGeneration:
    """Tests for generate_token_pair()."""

    @pytest.mark.asyncio
    async def test_generates_pair(self, token_service, user):
        pair = token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )
        assert "access_token" in pair
        assert "refresh_token" in pair
        assert "access_expires_at" in pair
        assert pair["access_token"] != pair["refresh_token"]


class TestAccessTokenValidation:
    """Tests for validate_access_token()."""

    @pytest.mark.asyncio
    async def test_valid_token(self, token_service, user):
        pair = token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )
        payload = token_service.validate_access_token(
            pair["access_token"]
        )
        assert payload["sub"] == str(user.id)
        assert payload["role"] == user.role

    @pytest.mark.asyncio
    async def test_garbage_token_raises(self, token_service):
        with pytest.raises(Exception):
            token_service.validate_access_token(
                "not.a.real.token"
            )


class TestRefreshTokenValidation:
    """Tests for validate_refresh_token()."""

    @pytest.mark.asyncio
    async def test_valid_refresh(self, token_service, user):
        pair = token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )
        payload = await token_service.validate_refresh_token(
            pair["refresh_token"]
        )
        assert payload["sub"] == str(user.id)
        assert payload["type"] == "refresh"

    @pytest.mark.asyncio
    async def test_revoked_refresh_raises(
        self, token_service, user
    ):
        pair = token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )
        await token_service.revoke_refresh_token(
            token_jti=pair["_refresh_jti"],
            user_id=str(user.id),
            expires_at=pair["_refresh_expires_at"],
        )
        with pytest.raises(Exception):
            await token_service.validate_refresh_token(
                pair["refresh_token"]
            )


class TestRevocation:
    """Tests for revoke_refresh_token()."""

    @pytest.mark.asyncio
    async def test_revoke_stores_jti(self, token_service, user):
        pair = token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )
        await token_service.revoke_refresh_token(
            token_jti=pair["_refresh_jti"],
            user_id=str(user.id),
            expires_at=pair["_refresh_expires_at"],
        )
        # Attempting to reuse should fail
        with pytest.raises(Exception):
            await token_service.validate_refresh_token(
                pair["refresh_token"]
            )


class TestRotation:
    """Tests for rotate_refresh_token()."""

    @pytest.mark.asyncio
    async def test_rotate_issues_new_pair(
        self, token_service, user
    ):
        old_pair = token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )
        new_pair = await token_service.rotate_refresh_token(
            old_pair["refresh_token"]
        )
        assert new_pair["access_token"] != old_pair["access_token"]
        assert (
            new_pair["refresh_token"] != old_pair["refresh_token"]
        )

    @pytest.mark.asyncio
    async def test_rotate_revokes_old(self, token_service, user):
        old_pair = token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )
        await token_service.rotate_refresh_token(
            old_pair["refresh_token"]
        )
        # Old refresh token should be revoked
        with pytest.raises(Exception):
            await token_service.validate_refresh_token(
                old_pair["refresh_token"]
            )
