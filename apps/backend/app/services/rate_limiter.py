"""Redis-backed rate limiter.

Uses INCR + EXPIRE for atomic, race-condition-free counters.
Each rate limit rule has its own key pattern and thresholds.
"""

import hashlib
from typing import Optional

from redis.asyncio import Redis

from app.config import Settings
from app.core.exceptions import RateLimitError
from app.core.logging import get_logger

logger = get_logger(__name__)


def _hash(value: str) -> str:
    """Hash a value for use in Redis keys (privacy + key-length safety)."""
    return hashlib.sha256(value.encode()).hexdigest()[:16]


class RateLimiter:
    """Redis-backed rate limiting for various actions."""

    def __init__(self, redis: Redis, settings: Settings) -> None:
        self._redis = redis
        self._settings = settings

    async def check_login(
        self, *, ip: str, email: str
    ) -> dict[str, str]:
        """Check and increment login attempt counter.

        Raises RateLimitError if limit exceeded.
        """
        key = f"rate:login:{_hash(ip)}:{_hash(email)}"
        return await self._check_and_increment(
            key=key,
            max_count=self._settings.rate_limit_login_max,
            window_seconds=self._settings.rate_limit_login_window_minutes * 60,
            action="login",
        )

    async def reset_login(self, *, ip: str, email: str) -> None:
        """Reset login attempts on successful login."""
        key = f"rate:login:{_hash(ip)}:{_hash(email)}"
        await self._redis.delete(key)

    async def check_register(self, *, ip: str) -> dict[str, str]:
        """Check and increment registration attempt counter."""
        key = f"rate:register:{_hash(ip)}"
        return await self._check_and_increment(
            key=key,
            max_count=self._settings.rate_limit_register_max,
            window_seconds=self._settings.rate_limit_register_window_minutes * 60,
            action="registration",
        )

    async def check_guest_query(
        self, *, ip: str, session_id: str
    ) -> dict[str, str]:
        """Check and increment guest query counter."""
        key = f"rate:guest:{_hash(ip)}:{_hash(session_id)}"
        return await self._check_and_increment(
            key=key,
            max_count=self._settings.rate_limit_guest_query_max,
            window_seconds=self._settings.rate_limit_guest_query_window_hours * 3600,
            action="guest query",
        )

    async def check_global(self, *, ip: str) -> dict[str, str]:
        """Check global per-IP rate limit."""
        key = f"rate:global:{_hash(ip)}"
        return await self._check_and_increment(
            key=key,
            max_count=self._settings.rate_limit_global_max,
            window_seconds=self._settings.rate_limit_global_window_seconds,
            action="request",
        )

    async def get_guest_remaining(
        self, *, ip: str, session_id: str
    ) -> int:
        """Get remaining guest queries."""
        key = f"rate:guest:{_hash(ip)}:{_hash(session_id)}"
        count = await self._redis.get(key)
        current = int(count) if count else 0
        return max(0, self._settings.rate_limit_guest_query_max - current)

    async def _check_and_increment(
        self,
        *,
        key: str,
        max_count: int,
        window_seconds: int,
        action: str,
    ) -> dict[str, str]:
        """Atomic check-and-increment via INCR + EXPIRE.

        Raises RateLimitError if the counter exceeds max_count.
        """
        count = await self._redis.incr(key)

        # Set TTL on first increment only
        if count == 1:
            await self._redis.expire(key, window_seconds)

        ttl = await self._redis.ttl(key)

        if count > max_count:
            logger.warning(
                "Rate limit exceeded: %s (key=%s, count=%d, max=%d)",
                action, key[:20], count, max_count,
            )
            raise RateLimitError(
                f"Too many {action} attempts. Please try again later.",
                details={
                    "retry_after": max(ttl, 0),
                    "remaining": 0,
                    "limit": max_count,
                },
            )

        return {
            "X-RateLimit-Limit": str(max_count),
            "X-RateLimit-Remaining": str(max(0, max_count - count)),
            "X-RateLimit-Reset": str(max(ttl, 0)),
        }
