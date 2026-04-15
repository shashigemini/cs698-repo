"""Token service — JWT generation, validation, and revocation."""

import uuid
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings
from app.core.exceptions import RefreshTokenError, TokenError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.repositories.revoked_token_repo import RevokedTokenRepository


class TokenService:
    """Handles JWT lifecycle: creation, validation, revocation."""

    def __init__(self, settings: Settings, session: AsyncSession) -> None:
        self._settings = settings
        self._session = session
        self._revoked_repo = RevokedTokenRepository(session)

    def generate_token_pair(
        self,
        *,
        user_id: str,
        role: str = "user",
    ) -> dict:
        """Generate access + refresh token pair.

        Returns:
            Dict with access_token, refresh_token, access_expires_at,
            and _refresh_jti (internal, for revocation tracking).
        """
        access_token, access_expires_at = create_access_token(
            self._settings,
            user_id=user_id,
            role=role,
        )

        refresh_token, refresh_expires_at, refresh_jti = create_refresh_token(
            self._settings,
            user_id=user_id,
        )

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "access_expires_at": access_expires_at,
            "_refresh_jti": refresh_jti,
            "_refresh_expires_at": refresh_expires_at,
        }

    def validate_access_token(self, token: str) -> dict:
        """Decode and validate an access token.

        Returns:
            Token payload dict with sub, role, jti, etc.

        Raises:
            TokenError: If token is invalid or expired.
        """
        return decode_token(
            self._settings,
            token,
            expected_type="access",
        )

    async def validate_refresh_token(self, token: str) -> dict:
        """Decode, validate, and check revocation status of refresh token.

        Returns:
            Token payload dict.

        Raises:
            RefreshTokenError: If token is invalid, expired, or revoked.
        """
        try:
            payload = decode_token(
                self._settings,
                token,
                expected_type="refresh",
            )
        except TokenError as e:
            raise RefreshTokenError(str(e)) from e

        jti = payload.get("jti")
        if jti and await self._revoked_repo.is_revoked(jti):
            raise RefreshTokenError("Refresh token has been revoked")

        return payload

    async def revoke_refresh_token(
        self,
        *,
        token_jti: str,
        user_id: str,
        expires_at: datetime,
    ) -> None:
        """Add a refresh token's JTI to the revocation list."""
        await self._revoked_repo.revoke(
            token_jti=token_jti,
            user_id=uuid.UUID(user_id),
            expires_at=expires_at,
        )
        await self._session.commit()

    async def rotate_refresh_token(
        self,
        old_token: str,
    ) -> dict:
        """Validate old refresh token, revoke it, issue new pair.

        Returns:
            New token pair dict.

        Raises:
            RefreshTokenError: If old token is invalid.
        """
        payload = await self.validate_refresh_token(old_token)

        user_id = payload["sub"]
        old_jti = payload.get("jti", "")
        old_exp = datetime.fromtimestamp(payload["exp"], tz=timezone.utc)

        # Revoke old refresh token
        await self.revoke_refresh_token(
            token_jti=old_jti,
            user_id=user_id,
            expires_at=old_exp,
        )

        # Issue new pair
        return self.generate_token_pair(
            user_id=user_id,
            role=payload.get("role", "user"),
        )
