"""Chat router — /api/chat/* endpoints.

Handles queries (guest + authenticated), conversation listing,
history loading, deletion, and export.
"""

from fastapi import APIRouter, Query, Request, Response

from app.config import get_settings
from app.dependencies import (
    ClientIP,
    CurrentUser,
    DbSession,
    OptionalUser,
    RateLimitSvc,
)
from app.schemas.chat_schemas import (
    ConversationSummary,
    ExportResponse,
    MessageResponse,
    QueryRequest,
    QueryResponse,
)
from app.schemas.common_schemas import MessageResponse as MsgResponse
from app.services.conversation_service import ConversationService
from app.services.rag_service import RAGService

router = APIRouter(prefix="/api/chat", tags=["Chat"])


@router.post("/query", response_model=QueryResponse)
async def chat_query(
    body: QueryRequest,
    request: Request,
    response: Response,
    session: DbSession,
    user: OptionalUser,
    rate_limiter: RateLimitSvc,
    client_ip: ClientIP,
) -> QueryResponse:
    """Send a query to the RAG pipeline.

    Supports both guest (rate-limited, no persistence) and
    authenticated (with conversation history) modes.
    """
    settings = get_settings()
    guest_remaining = None

    # Rate limit guests
    if user is None and body.guest_session_id:
        headers = await rate_limiter.check_guest_query(
            ip=client_ip,
            session_id=body.guest_session_id,
        )
        for k, v in headers.items():
            response.headers[k] = v
        guest_remaining = int(headers["X-RateLimit-Remaining"])

    rag_service = RAGService(settings, session)
    result = await rag_service.query(
        query_text=body.query,
        user_id=user["sub"] if user else None,
        conversation_id=body.conversation_id,
    )

    if guest_remaining is not None:
        result.guest_queries_remaining = guest_remaining

    return result


@router.get("/conversations", response_model=list[ConversationSummary])
async def list_conversations(
    user: CurrentUser,
    session: DbSession,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> list[ConversationSummary]:
    """List all conversations for the authenticated user."""
    service = ConversationService(session)
    return await service.list_conversations(user["sub"], limit=limit, offset=offset)


@router.get(
    "/conversations/{conversation_id}",
    response_model=list[MessageResponse],
)
async def load_conversation(
    conversation_id: str,
    user: CurrentUser,
    session: DbSession,
) -> list[MessageResponse]:
    """Load all messages in a conversation."""
    service = ConversationService(session)
    return await service.load_history(user["sub"], conversation_id)


@router.delete(
    "/conversations/{conversation_id}",
    response_model=MsgResponse,
)
async def delete_conversation(
    conversation_id: str,
    user: CurrentUser,
    session: DbSession,
) -> MsgResponse:
    """Delete a conversation and all its messages."""
    service = ConversationService(session)
    await service.delete_conversation(user["sub"], conversation_id)
    return MsgResponse(message="Conversation deleted successfully")


@router.post(
    "/conversations/{conversation_id}/export",
    response_model=ExportResponse,
)
async def export_conversation(
    conversation_id: str,
    user: CurrentUser,
    session: DbSession,
) -> ExportResponse:
    """Export a conversation as formatted Markdown."""
    service = ConversationService(session)
    return await service.export_conversation(user["sub"], conversation_id)
