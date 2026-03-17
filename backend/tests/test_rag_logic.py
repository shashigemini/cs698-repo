"""Unit tests for RAG logic — chunking, embedding, and LLM interaction mocks."""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.rag.chunker import chunk_text, Chunk, _approx_tokens
from app.rag.embedder import Embedder
from app.rag.llm_client import LLMClient
from app.rag.retriever import Retriever
from app.services.rag_service import RAGService
from app.core.exceptions import ValidationError, RetrievalError
import uuid

class TestChunker:
    def test_approx_tokens(self):
        assert _approx_tokens("hello world") == 2 # 2 / 0.75 = 2.6 -> 2
        assert _approx_tokens("") == 1 # max(1, 0)
        assert _approx_tokens("one two three four") == 5 # 4 / 0.75 = 5.3 -> 5

    def test_chunk_payload(self):
        chunk = Chunk(text="test", page=1, paragraph_id="p1", chunk_index=0)
        payload = chunk.to_payload(document_id="doc1", title="Title", author="Author")
        assert payload["document_id"] == "doc1"
        assert payload["text"] == "test"
        assert payload["author"] == "Author"

    def test_chunk_text_basic(self):
        pages = [{"page": 1, "text": "Sentence one. Sentence two.\n\nParagraph two."}]
        chunks = chunk_text(pages, target_tokens=10, overlap_tokens=0)
        assert len(chunks) >= 2
        assert chunks[0].page == 1
        assert "Sentence" in chunks[0].text

    def test_chunk_text_empty(self):
        assert chunk_text([]) == []
        assert chunk_text([{"page": 1, "text": "  "}]) == []

class TestEmbedder:
    @pytest.mark.asyncio
    async def test_embed_text_success(self, test_settings):
        with patch("app.rag.embedder.AsyncOpenAI") as mock_openai:
            mock_client = mock_openai.return_value
            mock_client.embeddings.create = AsyncMock()
            mock_client.embeddings.create.return_value.data = [
                MagicMock(embedding=[0.1] * 1536)
            ]
            
            embedder = Embedder(test_settings)
            vec = await embedder.embed_text("hello")
            assert len(vec) == 1536
            assert vec[0] == 0.1

    @pytest.mark.asyncio
    async def test_embed_retry_fails(self, test_settings):
        with patch("app.rag.embedder.AsyncOpenAI") as mock_openai:
            mock_client = mock_openai.return_value
            mock_client.embeddings.create = AsyncMock(side_effect=Exception("API Down"))
            
            # Set max retries to 0 for fast test
            test_settings.openai_max_retries = 0
            embedder = Embedder(test_settings)
            
            with pytest.raises(RetrievalError):
                await embedder.embed_text("hello")

class TestLLMClient:
    @pytest.mark.asyncio
    async def test_generate_answer(self, test_settings):
        with patch("app.rag.llm_client.AsyncOpenAI") as mock_openai:
            mock_client = mock_openai.return_value
            mock_client.chat.completions.create = AsyncMock()
            mock_client.chat.completions.create.return_value.choices = [
                MagicMock(message=MagicMock(content="The answer is 42"))
            ]
            
            llm = LLMClient(test_settings)
            answer = await llm.generate_answer(query="What?", passages=[{"text": "Ref"}], history=[])
            assert answer == "The answer is 42"

class TestRAGServiceUnit:
    @pytest.mark.asyncio
    async def test_query_validation(self, test_settings):
        # We don't need a real session for validation checks
        service = RAGService(test_settings, AsyncMock())
        
        with pytest.raises(ValidationError, match="Query too short"):
            await service.query(query_text="hi")
            
        with pytest.raises(ValidationError, match="Query too long"):
            await service.query(query_text="a" * 3000)

    @pytest.mark.asyncio
    async def test_query_authenticated_flow(self, test_settings):
        mock_session = AsyncMock()
        with patch("app.services.rag_service.Embedder") as mock_emb_cls, \
             patch("app.services.rag_service.Retriever") as mock_ret_cls, \
             patch("app.services.rag_service.LLMClient") as mock_llm_cls:
            
            mock_emb = mock_emb_cls.return_value
            mock_emb.embed_text = AsyncMock(return_value=[0.1]*1536)
            
            mock_ret = mock_ret_cls.return_value
            mock_ret.search = AsyncMock(return_value=[{
                "document_id": "doc1", "title": "T1", "page": 1, "paragraph_id": "p1", "text": "pass"
            }])
            
            mock_llm = mock_llm_cls.return_value
            mock_llm.generate_answer = AsyncMock(return_value="Answer")
            
            service = RAGService(test_settings, mock_session)
            # Mock the repos
            service._session_repo = AsyncMock()
            service._message_repo = AsyncMock()
            
            sess_id = uuid.uuid4()
            mock_session_obj = MagicMock()
            mock_session_obj.id = sess_id
            service._session_repo.create.return_value = mock_session_obj
            
            user_id = str(uuid.uuid4())
            res = await service.query(query_text="Valid query", user_id=user_id)
            
            assert res.answer == "Answer"
            assert res.conversation_id == str(sess_id)
            assert service._session_repo.create.called
            assert service._message_repo.create.call_count == 2
            assert mock_session.commit.called

class TestRetriever:
    @pytest.mark.asyncio
    async def test_search_success(self, test_settings):
        with patch("app.rag.retriever.AsyncQdrantClient") as mock_qdrant:
            mock_client = mock_qdrant.return_value
            mock_hit = MagicMock()
            mock_hit.payload = {"text": "found", "title": "Doc"}
            mock_hit.score = 0.95
            mock_client.search = AsyncMock(return_value=[mock_hit])
            
            retriever = Retriever(test_settings)
            res = await retriever.search(query_vector=[0.1]*1536)
            assert len(res) == 1
            assert res[0]["text"] == "found"
            assert res[0]["relevance_score"] == 0.95

    @pytest.mark.asyncio
    async def test_health_check(self, test_settings):
        with patch("app.rag.retriever.AsyncQdrantClient") as mock_qdrant:
            mock_client = mock_qdrant.return_value
            mock_client.get_collections = AsyncMock()
            
            retriever = Retriever(test_settings)
            assert await retriever.check_health() is True
