"""Background task for cleaning up expired revoked tokens."""

import asyncio

from app.core.logging import get_logger
from app.repositories.revoked_token_repo import RevokedTokenRepository

logger = get_logger(__name__)

class TokenCleanupTask:
    """Manages the periodic cleanup of expired tokens."""
    
    def __init__(self, interval_hours: int = 24) -> None:
        self.interval_seconds = interval_hours * 3600
        self._task: asyncio.Task[None] | None = None
        self._stop_event = asyncio.Event()

    def start(self) -> None:
        """Starts the background cleanup task."""
        if self._task is None:
            self._stop_event.clear()
            self._task = asyncio.create_task(self._run_loop())
            logger.info("Token cleanup background task started (interval: %dh)", self.interval_seconds // 3600)

    async def stop(self) -> None:
        """Stops the background cleanup task."""
        task = self._task
        if task:
            self._stop_event.set()
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
            self._task = None
            logger.info("Token cleanup background task stopped")

    async def _run_loop(self) -> None:
        """Runs the cleanup periodically."""
        # Wait a bit before first run to let app start up fully
        try:
            await asyncio.wait_for(self._stop_event.wait(), timeout=60)
        except asyncio.TimeoutError:
            pass

        while not self._stop_event.is_set():
            try:
                await self._cleanup()
            except Exception as e:
                logger.error("Error during token cleanup: %s", e)
            
            # Wait for the interval or until stopped
            try:
                await asyncio.wait_for(self._stop_event.wait(), timeout=self.interval_seconds)
            except asyncio.TimeoutError:
                pass # Continue loop

    async def _cleanup(self) -> None:
        """Perform the actual cleanup."""
        # Use local import to avoid circular dependency
        from app.dependencies import _database
        
        if _database is None:
            return
            
        async for session in _database.get_session():
            repo = RevokedTokenRepository(session)
            deleted_count = await repo.cleanup_expired()
            await session.commit()
            if deleted_count > 0:
                logger.info("Cleaned up %d expired revoked tokens", deleted_count)
            break
