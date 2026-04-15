"""User repository — data access for user and E2EE key operations."""

import base64
import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.e2ee_key import E2EEKey
from app.models.user import User


class UserRepository:
    """Encapsulates all user-related database queries."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(
        self,
        *,
        email: str,
        password_hash: str,
        role: str = "user",
        is_e2ee: bool = True,
    ) -> User:
        """Create a new user record."""
        user = User(
            email=email,
            password_hash=password_hash,
            role=role,
            is_e2ee=is_e2ee,
        )
        self._session.add(user)
        await self._session.flush()
        return user

    async def create_e2ee_keys(
        self,
        *,
        user_id: uuid.UUID,
        salt: bytes,
        wrapped_account_key: str,
        recovery_wrapped_ak: str,
    ) -> E2EEKey:
        """Store E2EE key material for a user."""
        keys = E2EEKey(
            user_id=user_id,
            salt=salt,
            wrapped_account_key=wrapped_account_key,
            recovery_wrapped_ak=recovery_wrapped_ak,
        )
        self._session.add(keys)
        await self._session.flush()
        return keys

    async def get_by_email(self, email: str) -> Optional[User]:
        """Look up a user by email address."""
        result = await self._session.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: uuid.UUID) -> Optional[User]:
        """Look up a user by ID."""
        result = await self._session.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_e2ee_keys(self, user_id: uuid.UUID) -> Optional[E2EEKey]:
        """Retrieve E2EE key material for a user."""
        result = await self._session.execute(
            select(E2EEKey).where(E2EEKey.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def update_e2ee_keys(
        self,
        user_id: uuid.UUID,
        *,
        password_hash: str,
        wrapped_account_key: str,
    ) -> None:
        """Update user's auth hash and wrapped AK (password change/recovery)."""
        user = await self.get_by_id(user_id)
        if user:
            user.password_hash = password_hash

        keys = await self.get_e2ee_keys(user_id)
        if keys:
            keys.wrapped_account_key = wrapped_account_key

        await self._session.flush()

    async def delete(self, user_id: uuid.UUID) -> bool:
        """Delete a user and all associated data (cascades)."""
        user = await self.get_by_id(user_id)
        if not user:
            return False
        await self._session.delete(user)
        await self._session.flush()
        return True
