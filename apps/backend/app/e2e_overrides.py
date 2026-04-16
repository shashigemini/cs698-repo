"""E2E test dependency overrides.

Replaces real OpenAI calls with stubs that return deterministic/pre-computed
results, allowing the rest of the RAG pipeline (Qdrant, DB, app logic) to be
tested end-to-end without spending API credits or making network calls.
"""

from fastapi import FastAPI
from app.rag.embedder import Embedder
from app.rag.llm_client import LLMClient
from app.services.rag_service import RAGService


class StubEmbedder:
    """Returns a fixed vector matching seeded Qdrant chunks."""

    def __init__(self, settings):
        self._settings = settings

    async def embed_text(self, text: str) -> list[float]:
        # Return a fixed 1536-dim vector to match seeded chunks
        return [0.1] * 1536

    async def embed_batch(
        self, texts: list[str], *, batch_size: int = 100
    ) -> list[list[float]]:
        return [[0.1] * 1536 for _ in texts]


class StubLLMClient:
    """Returns canned answers with citation-style formatting."""

    def __init__(self, settings):
        self._settings = settings

    async def generate_answer(
        self,
        *,
        query: str,
        passages: list[dict],
        history: list[dict],
    ) -> str:
        # A deterministic answer that references the retrieved context
        titles = [p.get("title", "Unknown") for p in passages[:2]]  # type: ignore
        context_str = ", ".join(titles) if titles else "no specific documents"
        
        return (
            f"Based on {context_str}, the answer to '{query}' involves "
            "spiritual wisdom and inner peace, as guided by the ancient scriptures. "
            "This is a mocked E2E response."
        )


def apply_e2e_overrides(app_instance: FastAPI) -> None:
    """Monkey-patch RAG components to use stubs instead of real API clients.
    
    Since components are instantiated inside service constructors, we patch
     the classes in the modules that have already imported them.
    """
    import app.rag.embedder
    import app.rag.llm_client
    import app.services.rag_service
    import app.services.document_service

    # 1. Patch the source modules (for any future imports)
    app.rag.embedder.Embedder = StubEmbedder  # type: ignore
    app.rag.llm_client.LLMClient = StubLLMClient  # type: ignore

    # 2. Patch the service modules (which have already imported them at the top level)
    app.services.rag_service.Embedder = StubEmbedder  # type: ignore
    app.services.rag_service.LLMClient = StubLLMClient  # type: ignore
    app.services.document_service.Embedder = StubEmbedder  # type: ignore
