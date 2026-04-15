"""Body size limit middleware.

Rejects requests with Content-Length exceeding the configured
maximum. This prevents payload bombing before the body is even
read into memory.
"""

from starlette.middleware.base import (
    BaseHTTPMiddleware,
    RequestResponseEndpoint,
)
from starlette.requests import Request
from starlette.responses import JSONResponse, Response


class BodySizeLimitMiddleware(BaseHTTPMiddleware):
    """Reject requests exceeding the configured body size limit."""

    def __init__(self, app, max_bytes: int = 1_048_576) -> None:
        super().__init__(app)
        self._max_bytes = max_bytes

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        if request.method == "OPTIONS":
            return await call_next(request)

        content_length = request.headers.get("content-length")

        if content_length and int(content_length) > self._max_bytes:
            return JSONResponse(
                status_code=413,
                content={
                    "error_code": "PAYLOAD_TOO_LARGE",
                    "message": (
                        f"Request body exceeds "
                        f"{self._max_bytes // 1024}KB limit"
                    ),
                },
            )

        return await call_next(request)
