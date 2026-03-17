"""Async Redis connection management.

Provides a connection pool and health check for Redis operations.
Used primarily for rate limiting and token revocation caching.
"""

import redis.asyncio as aioredis

from app.config import Settings


class RedisClient:
    """Manages the async Redis connection pool."""

    def __init__(self, settings: Settings) -> None:
        self._pool = aioredis.ConnectionPool.from_url(
            settings.redis_url,
            max_connections=20,
            decode_responses=True,
        )
        self.client = aioredis.Redis(connection_pool=self._pool)

    async def close(self) -> None:
        """Close all connections in the pool."""
        await self.client.aclose()

    async def check_health(self) -> bool:
        """Verify Redis connectivity with PING."""
        try:
            return await self.client.ping()
        except Exception:
            return False
