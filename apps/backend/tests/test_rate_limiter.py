"""Tests for rate limiter service."""

import pytest
import pytest_asyncio

from app.core.exceptions import RateLimitError
from app.services.rate_limiter import RateLimiter


class TestRateLimiter:
    """Tests for Redis-backed rate limiting."""

    def _make_limiter(self, mock_redis, test_settings):
        return RateLimiter(mock_redis, test_settings)

    @pytest.mark.asyncio
    async def test_login_within_limit(self, mock_redis, test_settings):
        """Login attempts within the limit should succeed."""
        limiter = self._make_limiter(mock_redis, test_settings)

        for _ in range(test_settings.rate_limit_login_max):
            await limiter.check_login(
                ip="192.168.1.1", email="user@test.com"
            )

    @pytest.mark.asyncio
    async def test_login_exceeds_limit(self, mock_redis, test_settings):
        """Exceeding login limit should raise RateLimitError."""
        limiter = self._make_limiter(mock_redis, test_settings)

        for _ in range(test_settings.rate_limit_login_max):
            await limiter.check_login(
                ip="192.168.1.1", email="user@test.com"
            )

        with pytest.raises(RateLimitError) as exc_info:
            await limiter.check_login(
                ip="192.168.1.1", email="user@test.com"
            )

        assert "Too many" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_register_within_limit(
        self, mock_redis, test_settings
    ):
        """Registration attempts within the limit should succeed."""
        limiter = self._make_limiter(mock_redis, test_settings)

        for _ in range(test_settings.rate_limit_register_max):
            await limiter.check_register(ip="10.0.0.1")

    @pytest.mark.asyncio
    async def test_register_exceeds_limit(
        self, mock_redis, test_settings
    ):
        """Exceeding registration limit should raise RateLimitError."""
        limiter = self._make_limiter(mock_redis, test_settings)

        for _ in range(test_settings.rate_limit_register_max):
            await limiter.check_register(ip="10.0.0.1")

        with pytest.raises(RateLimitError):
            await limiter.check_register(ip="10.0.0.1")

    @pytest.mark.asyncio
    async def test_guest_query_within_limit(
        self, mock_redis, test_settings
    ):
        """Guest queries within the limit should succeed."""
        limiter = self._make_limiter(mock_redis, test_settings)

        for _ in range(test_settings.rate_limit_guest_query_max):
            await limiter.check_guest_query(
                ip="172.16.0.1", session_id="guest-session-1"
            )

    @pytest.mark.asyncio
    async def test_guest_query_exceeds_limit(
        self, mock_redis, test_settings
    ):
        """Exceeding guest query limit should raise RateLimitError."""
        limiter = self._make_limiter(mock_redis, test_settings)

        for _ in range(test_settings.rate_limit_guest_query_max):
            await limiter.check_guest_query(
                ip="172.16.0.1", session_id="guest-session-1"
            )

        with pytest.raises(RateLimitError):
            await limiter.check_guest_query(
                ip="172.16.0.1", session_id="guest-session-1"
            )

    @pytest.mark.asyncio
    async def test_different_ips_have_separate_limits(
        self, mock_redis, test_settings
    ):
        """Different IPs should have independent counters."""
        limiter = self._make_limiter(mock_redis, test_settings)

        # Exhaust limit for IP 1
        for _ in range(test_settings.rate_limit_login_max):
            await limiter.check_login(ip="1.1.1.1", email="a@b.com")

        # IP 2 should still have quota
        await limiter.check_login(ip="2.2.2.2", email="a@b.com")

    @pytest.mark.asyncio
    async def test_get_guest_remaining(
        self, mock_redis, test_settings
    ):
        """Remaining count should decrease after each query."""
        limiter = self._make_limiter(mock_redis, test_settings)

        remaining = await limiter.get_guest_remaining(
            ip="10.0.0.2", session_id="sess-2"
        )
        assert remaining == test_settings.rate_limit_guest_query_max

        await limiter.check_guest_query(
            ip="10.0.0.2", session_id="sess-2"
        )

        remaining = await limiter.get_guest_remaining(
            ip="10.0.0.2", session_id="sess-2"
        )
        assert remaining == test_settings.rate_limit_guest_query_max - 1
