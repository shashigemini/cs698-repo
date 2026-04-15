"""PDF parsing module for text extraction."""

import io
import re
from typing import List

import pypdf
from pypdf.errors import PyPdfError

from app.core.exceptions import ValidationError
from app.core.logging import get_logger

logger = get_logger(__name__)


def parse_pdf(file_content: bytes) -> list[dict]:
    """Parse a PDF file and extract text page by page.

    Args:
        file_content: Raw bytes of the PDF.

    Returns:
        A list of dictionaries containing 'page' (1-indexed) and 'text'.

    Raises:
        ValidationError: If the PDF cannot be read or is corrupted.
    """
    try:
        pdf_file = io.BytesIO(file_content)
        reader = pypdf.PdfReader(pdf_file)

        pages_data = []
        for i, page in enumerate(reader.pages):
            text = page.extract_text()
            if text and text.strip():
                pages_data.append(
                    {
                        "page": i + 1,
                        "text": text.strip(),
                    }
                )

        if not pages_data:
            logger.warning("PDF parsed successfully but contained no extractable text.")
            
        return pages_data

    except PyPdfError as e:
        logger.error("Failed to parse PDF: %s", e)
        raise ValidationError("Invalid or corrupted PDF file") from e
    except Exception as e:
        logger.error("Unexpected error during PDF parsing: %s", e)
        raise ValidationError("Failed to parse PDF") from e
