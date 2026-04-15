"""Revoked token repository — JWT blacklisting data access."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.revoked_token import RevokedToken


class RevokedTokenRepository:
    """Encapsulates revoked token database queries."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def revoke(
        self,
        *,
        token_jti: str,
        user_id: uuid.UUID,
        expires_at: datetime,
    ) -> None:
        """Add a token JTI to the revocation list."""
        record = RevokedToken(
            token_jti=token_jti,
            user_id=user_id,
            expires_at=expires_at,
        )
        self._session.add(record)
        await self._session.flush()

    async def is_revoked(self, token_jti: str) -> bool:
        """Check if a token JTI has been revoked."""
        result = await self._session.execute(
            select(RevokedToken.id).where(
                RevokedToken.token_jti == token_jti
            )
        )
        return result.scalar_one_or_none() is not None

    async def revoke_all_for_user(self, user_id: uuid.UUID) -> None:
        """Revoke all tokens for a user (e.g., on account deletion)."""
        # For complete revocation, we rely on cascade delete
        # This method is for explicit bulk revocation if needed
        pass

    async def cleanup_expired(self) -> int:
        """Remove expired entries. Returns count of deleted rows."""
        now = datetime.now(timezone.utc)
        result = await self._session.execute(
            select(RevokedToken).where(
                RevokedToken.expires_at < now
            )
        )
        expired = result.scalars().all()
        for token in expired:
            await self._session.delete(token)
        await self._session.flush()
        return len(expired)
