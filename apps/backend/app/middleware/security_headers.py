"""Security headers middleware.

Injects browser security headers on every response to mitigate
XSS, clickjacking, MIME-sniffing, and other web-based attacks.
"""

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Adds security headers to all responses."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        response = await call_next(request)

        # Disable HSTS since we are on HTTP only for now
        # Setting max-age=0 clears any existing HSTS cache in the browser
        response.headers["Strict-Transport-Security"] = "max-age=0"
        
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        
        # Loosen CSP for the API. In a JSON API, we mainly care about frame-ancestors.
        # Strict CSP can sometimes interfere with how browsers handle XHR data.
        response.headers["Content-Security-Policy"] = (
            "default-src *; frame-ancestors 'none'"
        )
        response.headers["Cache-Control"] = (
            "no-store, no-cache, must-revalidate"
        )

        return response
