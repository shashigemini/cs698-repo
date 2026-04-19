"""Auth service — E2EE-aware registration, login, and account management.

This is the core business logic for authentication. It orchestrates
the UserRepository, TokenService, and RateLimiter.
"""

import base64
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings
from app.core.exceptions import (
    AccountNotFoundError,
    AuthError,
    EmailExistsError,
    KeysNotFoundError,
)
from app.core.logging import get_logger
from app.core.security import hash_password, verify_password
from app.repositories.user_repo import UserRepository
from app.services.token_service import TokenService

logger = get_logger(__name__)


class AuthService:
    """Handles all authentication operations."""

    def __init__(
        self,
        settings: Settings,
        session: AsyncSession,
    ) -> None:
        self._settings = settings
        self._session = session
        self._user_repo = UserRepository(session)
        self._token_service = TokenService(settings, session)

    async def register(
        self,
        *,
        email: str,
        client_auth_token: str,
        salt: str,
        wrapped_account_key: str,
        recovery_wrapped_ak: str,
    ) -> dict:
        """Register a new user with E2EE key material.

        Args:
            email: User's email address.
            client_auth_token: Base64 HKDF-derived auth token from LMK.
            salt: Base64-encoded Argon2id salt.
            wrapped_account_key: Base64 AES-GCM wrapped AccountKey.
            recovery_wrapped_ak: Base64 RecoveryKey-wrapped AccountKey.

        Returns:
            Dict with user_id, access_token, refresh_token, access_expires_at.

        Raises:
            EmailExistsError: If email is already registered.
        """
        existing = await self._user_repo.get_by_email(email)
        if existing:
            raise EmailExistsError()

        # Hash the client auth token (server never sees raw password)
        password_hash = hash_password(client_auth_token)

        # Decode salt from base64 to bytes
        try:
            salt_bytes = base64.urlsafe_b64decode(salt)
        except Exception:
            salt_bytes = base64.b64decode(salt)

        # Create user
        user = await self._user_repo.create(
            email=email,
            password_hash=password_hash,
            is_e2ee=True,
        )

        # Store E2EE keys
        await self._user_repo.create_e2ee_keys(
            user_id=user.id,
            salt=salt_bytes,
            wrapped_account_key=wrapped_account_key,
            recovery_wrapped_ak=recovery_wrapped_ak,
        )

        # Generate tokens
        token_pair = self._token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )

        await self._session.commit()
        logger.info("User registered successfully")

        return {
            "user_id": str(user.id),
            "access_token": token_pair["access_token"],
            "refresh_token": token_pair["refresh_token"],
            "access_expires_at": token_pair["access_expires_at"],
        }

    async def login_challenge(self, *, email: str) -> dict:
        """Step 1 of E2EE login: return user's salt.

        Uses constant-time behavior to avoid email enumeration:
        returns a fake salt if user doesn't exist.

        Args:
            email: User's email address.

        Returns:
            Dict with salt (base64-encoded).
        """
        user = await self._user_repo.get_by_email(email)

        if not user:
            # Return a deterministic fake salt to prevent enumeration
            # Hash the email to produce consistent salt per email
            import hashlib

            fake_salt = hashlib.sha256(email.encode()).digest()[:16]
            # Fake recovery string to match length/format
            fake_recovery = base64.urlsafe_b64encode(
                hashlib.sha512(email.encode()).digest()[:64]
            ).decode()
            return {
                "salt": base64.urlsafe_b64encode(fake_salt).decode(),
                "recovery_wrapped_ak": fake_recovery,
            }

        keys = await self._user_repo.get_e2ee_keys(user.id)
        if not keys:
            raise KeysNotFoundError()

        return {
            "salt": base64.urlsafe_b64encode(keys.salt).decode(),
            "recovery_wrapped_ak": keys.recovery_wrapped_ak,
        }

    async def login_verify(
        self,
        *,
        email: str,
        client_auth_token: str,
    ) -> dict:
        """Step 2 of E2EE login: verify auth token.

        Args:
            email: User's email address.
            client_auth_token: Base64 HKDF-derived auth token from LMK.

        Returns:
            Dict with user_id, tokens, and wrapped_account_key.

        Raises:
            AuthError: If credentials are invalid.
        """
        user = await self._user_repo.get_by_email(email)
        if not user:
            # Run hash anyway to avoid timing side-channel
            hash_password("dummy-token-for-timing")
            raise AuthError()

        if not verify_password(client_auth_token, user.password_hash):
            raise AuthError()

        keys = await self._user_repo.get_e2ee_keys(user.id)
        if not keys:
            raise KeysNotFoundError()

        # Promote to admin if email is in the ADMIN_EMAILS allowlist
        admin_emails = {e.lower() for e in self._settings.admin_emails}
        if user.email.lower() in admin_emails and user.role != "admin":
            user.role = "admin"
            await self._session.commit()
            logger.info("Promoted %s to admin via ADMIN_EMAILS allowlist", user.email)

        token_pair = self._token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )

        logger.info("User %s logged in with role: %s", email, user.role)

        return {
            "user_id": str(user.id),
            "access_token": token_pair["access_token"],
            "refresh_token": token_pair["refresh_token"],
            "access_expires_at": token_pair["access_expires_at"],
            "wrapped_account_key": keys.wrapped_account_key,
        }

    async def refresh_tokens(self, *, refresh_token: str) -> dict:
        """Rotate refresh token and issue new pair.

        Args:
            refresh_token: The current refresh token.

        Returns:
            New token pair dict.
        """
        result = await self._token_service.rotate_refresh_token(refresh_token)
        return {
            "access_token": result["access_token"],
            "refresh_token": result["refresh_token"],
            "access_expires_at": result["access_expires_at"],
        }

    async def logout(
        self,
        *,
        user_id: str,
        token_jti: str,
        token_exp: float,
    ) -> None:
        """Revoke the user's current refresh token.

        Args:
            user_id: The authenticated user's ID.
            token_jti: JTI of the token to revoke.
            token_exp: Expiry timestamp of the token.
        """
        from datetime import datetime, timezone

        await self._token_service.revoke_refresh_token(
            token_jti=token_jti,
            user_id=user_id,
            expires_at=datetime.fromtimestamp(token_exp, tz=timezone.utc),
        )
        logger.info("User logged out")

    async def delete_account(self, *, user_id: str) -> bool:
        """Permanently delete user and all associated data.

        Cascade deletes handle sessions, messages, keys, and tokens.
        """
        deleted = await self._user_repo.delete(uuid.UUID(user_id))
        if deleted:
            await self._session.commit()
            logger.info("User account deleted")
        return deleted

    async def change_password(
        self,
        *,
        user_id: str,
        new_auth_token: str,
        new_wrapped_account_key: str,
    ) -> None:
        """Update auth credentials after client-side password change.

        The client derives NewLMK, new ClientAuthToken, and re-wraps AK.
        Server just stores the new hash and wrapped key.
        """
        new_hash = hash_password(new_auth_token)
        await self._user_repo.update_e2ee_keys(
            uuid.UUID(user_id),
            password_hash=new_hash,
            wrapped_account_key=new_wrapped_account_key,
        )
        await self._session.commit()
        logger.info("User password changed")

    async def recover_account(
        self,
        *,
        email: str,
        new_auth_token: str,
        new_wrapped_account_key: str,
    ) -> dict:
        """Recover account with new credentials (after mnemonic verification on client).

        The client has already used the RecoveryKey to unwrap AK,
        derived NewLMK + new ClientAuthToken, and re-wrapped AK.
        """
        user = await self._user_repo.get_by_email(email)
        if not user:
            raise AccountNotFoundError()

        new_hash = hash_password(new_auth_token)
        await self._user_repo.update_e2ee_keys(
            user.id,
            password_hash=new_hash,
            wrapped_account_key=new_wrapped_account_key,
        )

        token_pair = self._token_service.generate_token_pair(
            user_id=str(user.id),
            role=user.role,
        )

        await self._session.commit()
        logger.info("Account recovered successfully")

        return {
            "user_id": str(user.id),
            "access_token": token_pair["access_token"],
            "refresh_token": token_pair["refresh_token"],
            "access_expires_at": token_pair["access_expires_at"],
            "wrapped_account_key": new_wrapped_account_key,
        }
