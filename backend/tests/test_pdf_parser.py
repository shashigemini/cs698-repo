"""Tests for the PDF parser module."""

import io
from unittest.mock import MagicMock, patch

import pytest
import pypdf

from app.core.exceptions import ValidationError
from app.rag.pdf_parser import parse_pdf

def test_parse_pdf_success():
    # Mocking PdfReader and its pages
    mock_reader = MagicMock()
    mock_page_1 = MagicMock()
    mock_page_1.extract_text.return_value = "Page 1 context."
    mock_page_2 = MagicMock()
    mock_page_2.extract_text.return_value = " Page 2 context. \n"
    mock_page_3 = MagicMock()
    mock_page_3.extract_text.return_value = "   " # Empty text after strip
    
    mock_reader.pages = [mock_page_1, mock_page_2, mock_page_3]

    with patch("app.rag.pdf_parser.pypdf.PdfReader", return_value=mock_reader):
        result = parse_pdf(b"dummy_pdf_bytes")
        
        assert len(result) == 2
        assert result[0] == {"page": 1, "text": "Page 1 context."}
        assert result[1] == {"page": 2, "text": "Page 2 context."}

def test_parse_pdf_empty_document():
    mock_reader = MagicMock()
    mock_reader.pages = []
    
    with patch("app.rag.pdf_parser.pypdf.PdfReader", return_value=mock_reader):
        result = parse_pdf(b"dummy_pdf_bytes")
        assert result == []

def test_parse_pdf_invalid_file():
    with patch("app.rag.pdf_parser.pypdf.PdfReader", side_effect=pypdf.errors.PyPdfError("Bad PDF")):
        with pytest.raises(ValidationError) as exc:
            parse_pdf(b"bad_pdf_bytes")
        assert "Invalid or corrupted PDF file" in str(exc.value)
