"""Tests for the PDF parser module."""

import io
from unittest.mock import MagicMock, patch

import pytest
import pypdf
from pypdf.errors import PyPdfError

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

    with patch("app.rag.pdf_parser.pypdf.PdfReader", return_value=mock_reader) as mock_pdf_reader:
        result = parse_pdf(b"dummy_pdf_bytes")
        
        assert mock_pdf_reader.call_count == 1
        args, _ = mock_pdf_reader.call_args
        assert isinstance(args[0], io.BytesIO)
        assert args[0].getvalue() == b"dummy_pdf_bytes"

        assert len(result) == 2
        assert result[0] == {"page": 1, "text": "Page 1 context."}
        assert result[1] == {"page": 2, "text": "Page 2 context."}

def test_parse_pdf_empty_document(caplog):
    mock_reader = MagicMock()
    mock_reader.pages = []
    
    with patch("app.rag.pdf_parser.pypdf.PdfReader", return_value=mock_reader) as mock_pdf_reader:
        result = parse_pdf(b"dummy_pdf_bytes")
        assert result == []

        assert mock_pdf_reader.call_count == 1
        args, _ = mock_pdf_reader.call_args
        assert isinstance(args[0], io.BytesIO)
        assert args[0].getvalue() == b"dummy_pdf_bytes"
        
    assert "PDF parsed successfully but contained no extractable text." in caplog.text

def test_parse_pdf_invalid_file(caplog):
    with patch("app.rag.pdf_parser.pypdf.PdfReader", side_effect=PyPdfError("Bad PDF")):
        with pytest.raises(ValidationError, match="Invalid or corrupted PDF file"):
            parse_pdf(b"bad_pdf_bytes")
            
    assert "Failed to parse PDF" in caplog.text

def test_parse_pdf_unexpected_error(caplog):
    with patch("app.rag.pdf_parser.pypdf.PdfReader", side_effect=Exception("Disk Error")):
        with pytest.raises(ValidationError, match="Failed to parse PDF"):
            parse_pdf(b"bad_pdf_bytes")
            
    assert "Unexpected error during PDF parsing" in caplog.text
