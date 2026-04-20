"""OpenAI embedding wrapper with batch support and retry."""

import asyncio
from typing import Optional

import openai
from openai import AsyncOpenAI

from app.config import Settings
from app.core.exceptions import RetrievalError
from app.core.logging import get_logger

logger = get_logger(__name__)

_NON_RETRYABLE_ERRORS = (openai.AuthenticationError, openai.BadRequestError)


class Embedder:
    """Generates embeddings via OpenAI's embedding API."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        # Disable SDK-level retries; _embed_with_retry owns retry logic
        self._client = AsyncOpenAI(
            api_key=settings.openai_api_key,
            max_retries=0,
        )
        self._model = settings.openai_embedding_model
        self._max_retries = settings.openai_max_retries

    async def embed_text(self, text: str) -> list[float]:
        """Embed a single text string.

        Returns:
            1536-dimensional embedding vector.
        """
        if self._settings.environment == "e2e_testing" or self._settings.openai_api_key == "e2e-mock-key":
            logger.info("E2E Mock Mode detected in Embedder, returning mock embedding")
            return [0.1] * 1536

        vectors = await self.embed_batch([text])
        return vectors[0]

    async def embed_batch(
        self, texts: list[str], *, batch_size: int = 100
    ) -> list[list[float]]:
        """Embed multiple texts with batching and retry.

        Args:
            texts: List of text strings to embed.
            batch_size: Max texts per API call.

        Returns:
            List of embedding vectors in same order as input.
        """
        all_embeddings = []

        for i in range(0, len(texts), batch_size):
            batch = texts[i : i + batch_size]
            embeddings = await self._embed_with_retry(batch)
            all_embeddings.extend(embeddings)

        return all_embeddings

    async def _embed_with_retry(
        self, texts: list[str]
    ) -> list[list[float]]:
        """Single batch embedding with exponential backoff retry."""
        for attempt in range(self._max_retries + 1):
            try:
                response = await self._client.embeddings.create(
                    input=texts,
                    model=self._model,
                )
                return [item.embedding for item in response.data]
            except Exception as e:
                if isinstance(e, _NON_RETRYABLE_ERRORS):
                    logger.error("Non-retryable OpenAI error during embedding: %s", e)
                    raise RetrievalError("Failed to generate embeddings") from e
                if attempt == self._max_retries:
                    logger.error(
                        "Embedding failed after %d retries: %s",
                        self._max_retries,
                        e,
                        exc_info=True,
                    )
                    raise RetrievalError(
                        "Failed to generate embeddings"
                    ) from e
                wait = 2**attempt
                logger.warning(
                    "Embedding attempt %d failed, retrying in %ds: %s",
                    attempt + 1, wait, e,
                )
                await asyncio.sleep(wait)

        # Should not reach here, but satisfies type checker
        raise RetrievalError("Embedding failed")
