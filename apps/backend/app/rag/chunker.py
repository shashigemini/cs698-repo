"""Sentence-based document chunker for PDF ingestion."""

import re
from typing import Optional

from app.core.logging import get_logger

logger = get_logger(__name__)


class Chunk:
    """Represents a single text chunk with source metadata."""

    def __init__(
        self,
        *,
        text: str,
        page: int,
        paragraph_id: str,
        chunk_index: int,
    ) -> None:
        self.text = text
        self.page = page
        self.paragraph_id = paragraph_id
        self.chunk_index = chunk_index

    def to_payload(self, *, document_id: str, title: str, author: Optional[str] = None) -> dict:
        """Convert to Qdrant payload format."""
        return {
            "document_id": document_id,
            "title": title,
            "page": self.page,
            "paragraph_id": self.paragraph_id,
            "text": self.text,
            "chunk_index": self.chunk_index,
            "author": author or "",
        }


def chunk_text(
    pages: list[dict],
    *,
    target_tokens: int = 500,
    overlap_tokens: int = 50,
) -> list[Chunk]:
    """Split document pages into overlapping chunks.

    Args:
        pages: List of {"page": int, "text": str} dicts.
        target_tokens: Target chunk size in approximate tokens.
        overlap_tokens: Number of tokens to overlap between chunks.

    Returns:
        List of Chunk objects with page and paragraph metadata.
    """
    chunks = []
    chunk_index = 0

    current_chunk: list[str] = []
    current_len = 0
    start_page = 1
    start_paragraph_id = "p1"

    for page_data in pages:
        page_num = page_data["page"]
        text = page_data["text"].strip()
        if not text:
            continue

        # Split into paragraphs
        paragraphs = re.split(r"\n\s*\n", text)

        for para_idx, paragraph in enumerate(paragraphs):
            paragraph = paragraph.strip()
            if not paragraph:
                continue

            paragraph_id = f"p{para_idx + 1}"

            # Split into sentences
            sentences = re.split(r"(?<=[.!?])\s+", paragraph)

            for sentence in sentences:
                sentence_len = _approx_tokens(sentence)
                
                if current_len == 0:
                    start_page = page_num
                    start_paragraph_id = paragraph_id

                if current_len + sentence_len > target_tokens and current_chunk:
                    # Emit chunk
                    chunks.append(Chunk(
                        text=" ".join(current_chunk),
                        page=start_page,
                        paragraph_id=start_paragraph_id,
                        chunk_index=chunk_index,
                    ))
                    chunk_index += 1

                    # Keep overlap
                    overlap_text = " ".join(current_chunk)
                    overlap_words = overlap_text.split()
                    keep = min(
                        len(overlap_words),
                        overlap_tokens,
                    )
                    current_chunk = overlap_words[-keep:] if keep > 0 else []
                    current_len = _approx_tokens(" ".join(current_chunk))
                    
                    # Ensure start metadata resets to the current element after overlap
                    start_page = page_num
                    start_paragraph_id = paragraph_id

                current_chunk.append(sentence)
                current_len += sentence_len

    # Emit remaining text
    if current_chunk:
        chunks.append(Chunk(
            text=" ".join(current_chunk),
            page=start_page,
            paragraph_id=start_paragraph_id,
            chunk_index=chunk_index,
        ))
        chunk_index += 1

    logger.info("Created %d chunks from %d pages", len(chunks), len(pages))
    return chunks


def _approx_tokens(text: str) -> int:
    """Approximate token count (1 token ≈ 0.75 words)."""
    return max(1, int(len(text.split()) / 0.75))
