"""OpenAI LLM client with structured prompting and retry."""

import asyncio

from openai import AsyncOpenAI

from app.config import Settings
from app.core.exceptions import LLMError
from app.core.logging import get_logger
from app.rag.prompts import (
    SYSTEM_PROMPT,
    USER_PROMPT_TEMPLATE,
    format_context,
    format_history,
)

logger = get_logger(__name__)


class LLMClient:
    """Generates answers using OpenAI's chat completions API."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._client = AsyncOpenAI(api_key=settings.openai_api_key)
        self._model = settings.openai_model
        self._max_tokens = settings.openai_max_response_tokens
        self._temperature = settings.openai_temperature
        self._timeout = settings.openai_timeout_seconds
        self._max_retries = settings.openai_max_retries

    async def generate_answer(
        self,
        *,
        query: str,
        passages: list[dict],
        history: list[dict],
    ) -> str:
        """Generate an answer grounded in retrieved passages.

        Args:
            query: The user's question.
            passages: Retrieved context passages from Qdrant.
            history: Previous conversation messages.

        Returns:
            The generated answer text.

        Raises:
            LLMError: If generation fails after retries.
        """
        system_content = SYSTEM_PROMPT.format(
            context=format_context(passages),
            history=format_history(history),
        )
        user_content = USER_PROMPT_TEMPLATE.format(query=query)

        if self._settings.environment == "e2e_testing" or self._settings.openai_api_key == "e2e-mock-key":
            logger.info("E2E Mock Mode detected in LLMClient, returning mock answer")
            return "This involves spiritual wisdom and inner peace, as guided by the ancient scriptures."

        for attempt in range(self._max_retries + 1):
            try:
                response = await self._client.chat.completions.create(
                    model=self._model,
                    messages=[
                        {"role": "system", "content": system_content},
                        {"role": "user", "content": user_content},
                    ],
                    max_tokens=self._max_tokens,
                    temperature=self._temperature,
                    timeout=self._timeout,
                )

                answer = response.choices[0].message.content
                logger.info(
                    "LLM generated answer (tokens: %d)",
                    response.usage.completion_tokens
                    if response.usage
                    else 0,
                )
                return answer or ""

            except Exception as e:
                if attempt == self._max_retries:
                    logger.error(
                        "LLM generation failed after %d retries",
                        self._max_retries,
                    )
                    raise LLMError(
                        "AI service temporarily unavailable"
                    ) from e

                wait = 2**attempt
                logger.warning(
                    "LLM attempt %d failed, retrying in %ds",
                    attempt + 1, wait,
                )
                await asyncio.sleep(wait)

        raise LLMError("Generation failed")
