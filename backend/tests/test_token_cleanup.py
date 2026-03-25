"""Tests for app.services.token_cleanup — background task lifecycle."""

import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.token_cleanup import TokenCleanupTask


class TestTokenCleanupTask:
    """Tests for the background token cleanup task."""

    def test_init_sets_interval(self):
        task = TokenCleanupTask(interval_hours=12)
        assert task.interval_seconds == 12 * 3600
        assert task._task is None

    @pytest.mark.asyncio
    async def test_start_creates_task(self):
        task = TokenCleanupTask(interval_hours=1)
        task.start()
        assert task._task is not None
        # Cleanup
        await task.stop()

    @pytest.mark.asyncio
    async def test_stop_cancels_task(self):
        task = TokenCleanupTask(interval_hours=1)
        task.start()
        assert task._task is not None
        await task.stop()
        assert task._task is None

    @pytest.mark.asyncio
    async def test_cleanup_with_no_database(self):
        """_cleanup should return early when _database is None."""
        task = TokenCleanupTask(interval_hours=1)
        with patch(
            "app.services.token_cleanup.RevokedTokenRepository"
        ), patch(
            "app.dependencies._database", None
        ):
            await task._cleanup()

    @pytest.mark.asyncio
    async def test_cleanup_with_mock_database(self):
        """_cleanup should call repo and commit."""
        task = TokenCleanupTask(interval_hours=1)

        mock_session = AsyncMock()
        mock_repo = MagicMock()
        mock_repo.cleanup_expired = AsyncMock(return_value=3)

        mock_db = MagicMock()

        async def mock_get_session():
            yield mock_session

        mock_db.get_session = mock_get_session

        with patch(
            "app.services.token_cleanup.RevokedTokenRepository",
            return_value=mock_repo,
        ), patch(
            "app.dependencies._database", mock_db
        ):
            await task._cleanup()
            mock_repo.cleanup_expired.assert_called_once()
            mock_session.commit.assert_called_once()
