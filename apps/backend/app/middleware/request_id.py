"""Request ID middleware — adds X-Request-ID to every request/response.

Also sets logging context variables so all downstream log entries
are automatically tagged with request_id, path, and method.
"""

import uuid

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.core.logging import (
    request_id_var,
    request_method_var,
    request_path_var,
)


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Injects a unique request ID for tracing."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request_id = request.headers.get(
            "X-Request-ID", str(uuid.uuid4())
        )
        # Store on request state for downstream logging
        request.state.request_id = request_id

        # Set context vars so all log records include this info
        request_id_var.set(request_id)
        request_path_var.set(request.url.path)
        request_method_var.set(request.method)

        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response
