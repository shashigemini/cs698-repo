"""Admin router — /admin/* endpoints.

Handles document ingestion, listing, and deletion.
Requires admin role authentication.
"""

from fastapi import APIRouter, BackgroundTasks, File, Form, UploadFile
import logging

from app.config import get_settings
from app.dependencies import AdminUser, DbSession
from app.schemas.common_schemas import ConfigUpdateRequest, MessageResponse
from app.services.document_service import DocumentService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/admin", tags=["Admin"])


@router.post("/documents/ingest")
async def ingest_document(
    admin: AdminUser,
    session: DbSession,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    title: str = Form(...),
    logical_book_id: str = Form(...),
    author: str = Form(default=None),
    edition: str = Form(default=None),
):
    """Upload and ingest a PDF document.

    The file is validated (magic bytes + extension), stored with
    a UUID filename, and queued for chunking + embedding.
    """
    settings = get_settings()
    content = await file.read()

    service = DocumentService(settings, session)
    result = await service.ingest(
        file_content=content,
        filename=file.filename or "unknown.pdf",
        title=title,
        logical_book_id=logical_book_id,
        background_tasks=background_tasks,
        author=author,
        edition=edition,
    )
    return result


@router.get("/documents")
async def list_documents(
    admin: AdminUser,
    session: DbSession,
):
    """List all ingested documents and their status."""
    settings = get_settings()
    service = DocumentService(settings, session)
    return await service.list_documents()


@router.delete("/documents/{document_id}")
async def delete_document(
    document_id: str,
    admin: AdminUser,
    session: DbSession,
):
    """Delete a document and its stored file."""
    settings = get_settings()
    service = DocumentService(settings, session)
    deleted = await service.delete_document(document_id)
    if deleted:
        return MessageResponse(
            message="Document deleted successfully"
        )
    return MessageResponse(message="Document not found")


@router.put("/config")
async def update_config(
    admin: AdminUser,
    update: ConfigUpdateRequest,
):
    """Update global application configuration (demo mode only)."""
    settings = get_settings()
    
    if update.openai_api_key is not None:
        settings.openai_api_key = update.openai_api_key
        logger.info("OpenAI API Key updated via Admin API")
    if update.openai_model is not None:
        settings.openai_model = update.openai_model
        logger.info("OpenAI Model updated to: %s", update.openai_model)
    if update.openai_temperature is not None:
        settings.openai_temperature = update.openai_temperature
        logger.info("OpenAI Temperature updated to: %s", update.openai_temperature)
        
    return MessageResponse(message="Configuration updated successfully")


@router.get("/config")
async def get_config(
    admin: AdminUser,
):
    """Get current configuration (masked for security)."""
    settings = get_settings()
    
    def mask_key(key: str) -> str:
        if not key or len(key) < 8:
            return "Not set"
        return f"{key[:4]}...{key[-3:]}"
        
    return {
        "openai_api_key": mask_key(settings.openai_api_key),
        "openai_model": settings.openai_model,
        "openai_temperature": settings.openai_temperature,
    }
