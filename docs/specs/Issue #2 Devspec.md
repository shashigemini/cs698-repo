Header
As a new visitor, I want to create a secure account so that my access to the proprietary knowledge base is authorized and personalized.

Architecture Diagram

Where Components Run
Client: Flutter app with web (cookies + CSRF) and mobile (secure storage)
Backend: FastAPI auth endpoints with rate limiting
Data: users and revoked_tokens tables in PostgreSQL
Information Flows
Registration Flow
User submits email + password to /auth/register
Backend checks rate limit (3 registrations per hour per IP)
AuthService validates input:
Email: RFC 5322 format, max 255 chars
Password: Min 8 chars, must include uppercase, lowercase, digit, special char
Check if email already exists in users table
Hash password with Argon2 (time cost=2, memory cost=100MB, parallelism=8)
Create user record in PostgreSQL
Generate JWT tokens:
Access token (15 min TTL) with claims: {user_id, role, exp, iat}
Refresh token (7 days TTL) with claims: {user_id, jti (unique ID), exp, iat}
Web: Set tokens as HttpOnly cookies + return CSRF token
Mobile: Return tokens in response body
Client stores tokens and transitions to authenticated mode
Login Flow
User submits email + password to /auth/login
Backend checks rate limit (5 attempts per 15 minutes per IP)
AuthService queries users table by email
Verify password hash using Argon2
On success: Generate and return tokens (same as registration)
On failure: Return INVALID_CREDENTIALS error (no detail on which field failed)
Token Refresh Flow
Web: Refresh token automatically read from HttpOnly cookie
Mobile: Client sends refresh token in request body
Backend verifies refresh token:
Check signature and expiration
Check if token JTI is in revoked_tokens table
On valid token:
Generate new access token (15 min TTL)
Generate new refresh token (7 days TTL) and revoke old one
Add old refresh token JTI to revoked_tokens table
Return new token pair
Logout Flow
Client sends logout request with access token
Backend verifies access token
Extract refresh token JTI from user's session
Add refresh token JTI to revoked_tokens table
Web: Clear HttpOnly cookies
Mobile: Client deletes tokens from secure storage
Return success response
Class Diagram

List of Classes
AuthService: Core authentication logic (registration, login, token management)
User: User entity representing database record
TokenPair: Container for access and refresh tokens with metadata
RevokedToken: Tracks invalidated refresh tokens
RateLimiter: Controls login/registration attempts
PasswordValidator: Validates password complexity
EmailValidator: Validates email format
State Diagrams

Flow Chart (Registration)

Flow Chart (Login)

Development Risks and Failures
Incorrect token rotation or refresh logic

Risk: Users logged out unexpectedly, security vulnerabilities
Mitigation: Comprehensive unit tests for token lifecycle, E2E tests for refresh scenarios
Misconfiguring CSRF protection on web

Risk: Blocked legitimate requests or CSRF vulnerabilities
Mitigation: Test CSRF with different origin scenarios, follow OWASP guidelines
Password hashing misconfiguration

Risk: Weak password security, brute force attacks
Mitigation: Use well-tested library (passlib with Argon2), verify configuration against OWASP standards
Token storage leakage on mobile

Risk: Token theft if insecure storage used
Mitigation: Use flutter_secure_storage, test on rooted/jailbroken devices
Rate limiting bypass

Risk: Brute force attacks via multiple IPs or session rotation
Mitigation: Combine IP + email rate limiting, implement progressive delays
JWT token size bloat

Risk: Large tokens increase bandwidth and cookie storage issues
Mitigation: Keep claims minimal (user_id, role, exp, iat only)
Technology Stack
Backend
FastAPI: OAuth2/JWT security patterns
passlib[argon2]: Password hashing (Argon2id algorithm)
python-jose[cryptography]: JWT encoding/decoding
PostgreSQL 14+: User and revoked token storage
pydantic: Request/response validation
slowapi: Rate limiting (MVP in-memory, production with Redis)
Frontend
Flutter: Cross-platform UI
flutter_secure_storage: Token storage on mobile (iOS Keychain, Android KeyStore)
dio: HTTP client with interceptors for token refresh
Riverpod or Bloc: State management for auth state
Security Libraries
argon2-cffi: Argon2 password hashing (Python binding)
cryptography: RSA/HMAC for JWT signing
email-validator: RFC 5322 email validation
APIs / Public Interfaces
REST APIs (External Contracts)
Purpose: HTTP endpoints that external clients (Flutter app, web clients) call over the network to authenticate users, manage sessions, and handle tokens.

POST /auth/register
Description: Create a new user account with email and password.

Authentication: None required

Request Headers:

Content-Type: application/json
Request Body:

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
Validation Rules:

Email: RFC 5322 format, max 255 characters, case-insensitive
Password: Min 8 characters, must contain:
At least 1 uppercase letter (A-Z)
At least 1 lowercase letter (a-z)
At least 1 digit (0-9)
At least 1 special character (!@#$%^&*)
Success Response (200) - Mobile:

{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 900,
  "token_type": "Bearer"
}
Success Response (200) - Web:

{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "csrf_token": "a1b2c3d4e5f6..."
}
Note: On web, access_token and refresh_token are set as HttpOnly cookies (not in response body).

Response Headers (Web):

Set-Cookie: access_token=eyJ...; HttpOnly; Secure; SameSite=Strict; Max-Age=900; Path=/
Set-Cookie: refresh_token=eyJ...; HttpOnly; Secure; SameSite=Strict; Max-Age=604800; Path=/
Error Responses:

Email Already Exists (400):

{
  "error_code": "EMAIL_ALREADY_EXISTS",
  "message": "An account with this email already exists.",
  "details": null
}
Validation Error (400):

{
  "error_code": "VALIDATION_ERROR",
  "message": "Password does not meet complexity requirements.",
  "details": {
    "field": "password",
    "requirements": [
      "min_8_chars",
      "uppercase",
      "lowercase",
      "digit",
      "special_char"
    ],
    "missing": ["uppercase", "special_char"]
  }
}
Rate Limit Exceeded (429):

{
  "error_code": "REGISTRATION_RATE_LIMIT_EXCEEDED",
  "message": "Too many registration attempts. Please try again later.",
  "details": {
    "retry_after": 3600,
    "limit": 3,
    "window": "1 hour"
  }
}
POST /auth/login
Description: Authenticate a user with email and password.

Authentication: None required

Request Headers:

Content-Type: application/json
Request Body:

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
Success Response (200):
Same format as /auth/register (platform-dependent)

Error Responses:

Invalid Credentials (401):

{
  "error_code": "INVALID_CREDENTIALS",
  "message": "Email or password is incorrect.",
  "details": null
}
Note: Intentionally vague - doesn't specify whether email or password is wrong (security best practice).

Rate Limit Exceeded (429):

{
  "error_code": "LOGIN_RATE_LIMIT_EXCEEDED",
  "message": "Too many login attempts. Please try again later.",
  "details": {
    "retry_after": 900,
    "limit": 5,
    "window": "15 minutes"
  }
}
POST /auth/refresh
Description: Obtain a new access token using a valid refresh token. Implements token rotation (old refresh token is revoked).

Authentication: Refresh token required

Request Headers - Mobile:

Content-Type: application/json
Request Body - Mobile:

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
Request Headers - Web:

Cookie: refresh_token=eyJ...
Note: On web, refresh token is automatically read from HttpOnly cookie (no request body needed).

Success Response (200):

{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 900,
  "token_type": "Bearer"
}
Token Rotation Behavior:

Old refresh token JTI is added to revoked_tokens table
New refresh token issued with new JTI
Client must replace old token with new token
Error Response (401):

{
  "error_code": "INVALID_REFRESH_TOKEN",
  "message": "Refresh token is invalid or expired. Please log in again.",
  "details": {
    "reason": "expired" | "revoked" | "invalid_signature"
  }
}
POST /auth/logout
Description: Invalidate the current refresh token and log out the user.

Authentication: Access token required

Request Headers:

Authorization: Bearer <access_token>
Request Body: None

Success Response (200):

{
  "message": "Logged out successfully"
}
Response Headers (Web):

Set-Cookie: access_token=; HttpOnly; Secure; SameSite=Strict; Max-Age=0; Path=/
Set-Cookie: refresh_token=; HttpOnly; Secure; SameSite=Strict; Max-Age=0; Path=/
Behavior:

Backend extracts refresh token JTI from user session and adds to revoked_tokens table
Web: Clears HttpOnly cookies in response
Mobile: Client deletes tokens from secure storage after receiving response
Error Response (401):

{
  "error_code": "UNAUTHORIZED",
  "message": "Invalid or expired access token.",
  "details": null
}
Token Handling by Platform
Web
Token Storage:

Access token: HttpOnly cookie, SameSite=Strict, Secure flag
Refresh token: HttpOnly cookie, SameSite=Strict, Secure flag
CSRF token: Non-HttpOnly cookie or localStorage (sent in X-CSRF-Token header)
Request Flow:

Browser automatically sends cookies with requests
Client includes CSRF token in custom header for mutation requests (POST, PUT, DELETE)
Backend validates both cookie tokens and CSRF token
CORS Configuration:

Allowed origins: Whitelist of production domains
Allow credentials: true (for cookies)
Allowed headers: Authorization, Content-Type, X-CSRF-Token
Allowed methods: GET, POST, PUT, DELETE, OPTIONS
Mobile
Token Storage:

Both tokens stored using flutter_secure_storage:
iOS: Keychain with accessibility level kSecAttrAccessibleAfterFirstUnlock
Android: EncryptedSharedPreferences backed by KeyStore
Request Flow:

Client reads tokens from secure storage
Adds Authorization: Bearer <access_token> header
On 401 response, attempts token refresh
On successful refresh, retries original request
Token Refresh Strategy:

Interceptor in dio HTTP client
On 401 response with error_code: "UNAUTHORIZED":
Lock concurrent requests
Call /auth/refresh with refresh token
Update stored tokens
Retry failed requests with new access token
On refresh failure: Clear tokens, redirect to login
Public Interfaces (Internal Contracts)
Purpose: Stable Python classes and methods that other backend modules depend on for authentication, authorization, and token management. Private methods and implementation details are excluded.

AuthService
Module: app/services/auth_service.py

Responsibility: Core authentication logic including user registration, login, token generation, and password management.

Public Methods:

class AuthService:
    def register(
        self,
        email: str,
        password: str
    ) -> Tuple[User, TokenPair]:
        """
        Register a new user account.
        
        Args:
            email: User email (RFC 5322 format, max 255 chars)
            password: Plain text password (will be hashed)
        
        Returns:
            Tuple of (User, TokenPair)
        
        Raises:
            EmailAlreadyExistsError: Email is already registered
            ValidationError: Email or password validation failed
            DatabaseError: User creation failed
        
        Contract:
            - Email is normalized to lowercase before storage
            - Password is hashed with Argon2id (never stored plain)
            - Default role is 'user'
            - Transactional: rollback on any error
        """
    
    def login(
        self,
        email: str,
        password: str
    ) -> Tuple[User, TokenPair]:
        """
        Authenticate a user with email and password.
        
        Args:
            email: User email
            password: Plain text password
        
        Returns:
            Tuple of (User, TokenPair)
        
        Raises:
            InvalidCredentialsError: Email not found or password incorrect
            DatabaseError: Query failed
        
        Contract:
            - Email lookup is case-insensitive
            - Uses constant-time password comparison
            - Does not reveal whether email or password is wrong
            - Rate limiting applied at endpoint level (not in service)
        """
    
    def refresh_token(
        self,
        refresh_token: str
    ) -> TokenPair:
        """
        Generate new token pair using valid refresh token.
        
        Args:
            refresh_token: JWT refresh token string
        
        Returns:
            New TokenPair with rotated refresh token
        
        Raises:
            InvalidRefreshTokenError: Token expired, revoked, or invalid
            DatabaseError: Token revocation write failed
        
        Contract:
            - Old refresh token is revoked (added to revoked_tokens table)
            - New refresh token has different JTI
            - Access token TTL: 15 minutes
            - Refresh token TTL: 7 days
            - Atomic operation: both tokens generated or neither
        """
    
    def logout(
        self,
        user_id: UUID,
        refresh_token_jti: str
    ) -> None:
        """
        Logout user by revoking refresh token.
        
        Args:
            user_id: User UUID
            refresh_token_jti: JWT ID of refresh token to revoke
        
        Raises:
            DatabaseError: Token revocation write failed
        
        Contract:
            - Adds refresh_token_jti to revoked_tokens table
            - Idempotent: safe to call multiple times with same JTI
            - Access tokens cannot be revoked (rely on short TTL)
        """

    def delete_account(
        self,
        user_id: UUID
    ) -> None:
        """
        Permanently delete the user's account and all associated data.
        
        Args:
            user_id: User UUID
        
        Contract:
            - Transactional: rollback on any error
            - Cascades to all user-related data (sessions, messages)
        """
    
    def verify_access_token(
        self,
        access_token: str
    ) -> User:
        """
        Verify access token and return user.
        
        Args:
            access_token: JWT access token string
        
        Returns:
            User object with id, email, role
        
        Raises:
            UnauthorizedError: Token expired, invalid signature, or malformed
            DatabaseError: User lookup failed
        
        Contract:
            - Validates signature, expiration, and token type
            - Does NOT check revoked_tokens (access tokens are short-lived)
            - Returns fresh user data from database (not cached)
        """
    
    def hash_password(
        self,
        password: str
    ) -> str:
        """
        Hash password using Argon2id.
        
        Args:
            password: Plain text password
        
        Returns:
            Hashed password string (Argon2 format)
        
        Contract:
            - Algorithm: Argon2id
            - Time cost: 2 iterations
            - Memory cost: 100 MB
            - Parallelism: 8 threads
            - Salt: 16 bytes (auto-generated)
            - Hash length: 32 bytes
        """
    
    def verify_password(
        self,
        password: str,
        password_hash: str
    ) -> bool:
        """
        Verify password against hash.
        
        Args:
            password: Plain text password
            password_hash: Argon2 hash string
        
        Returns:
            True if password matches, False otherwise
        
        Contract:
            - Uses constant-time comparison (timing-attack resistant)
            - Never raises exception on mismatch (returns False)
        """
Data Transfer Objects:

@dataclass
class TokenPair:
    """Access and refresh token pair with expiry metadata"""
    access_token: str
    refresh_token: str
    expires_in: int  # Access token TTL in seconds (900)
    access_expires_at: datetime
    refresh_expires_at: datetime
    token_type: str = "Bearer"

@dataclass
class User:
    """User entity"""
    id: UUID
    email: str
    role: str
    created_at: datetime
    updated_at: datetime
    # Note: password_hash excluded from this DTO (internal only)
Internal Methods (not part of public interface):

_generate_jwt(): Private JWT generation logic
_decode_jwt(): Private JWT decoding logic
_create_user_record(): Private database insertion
_get_user_by_email(): Private database query
RateLimiter
Module: app/services/rate_limiter.py

Responsibility: Rate limiting for authentication endpoints to prevent brute force attacks.

Public Methods:

class RateLimiter:
    def check_login_allowed(
        self,
        ip_address: str,
        email: str
    ) -> Tuple[bool, int]:
        """
        Check if login attempt is allowed.
        
        Args:
            ip_address: Client IP address
            email: Email being used for login
        
        Returns:
            Tuple of (allowed: bool, retry_after_seconds: int)
        
        Contract:
            - Limit: 5 attempts per 15 minutes per (IP + email) combination
            - Key: login_rate:{ip}:{email_hash}
            - Progressive delays: 1s, 2s, 5s, 10s, 30s
            - Counter resets on successful login or after 15 minutes
        """
    
    def check_register_allowed(
        self,
        ip_address: str
    ) -> Tuple[bool, int]:
        """
        Check if registration attempt is allowed.
        
        Args:
            ip_address: Client IP address
        
        Returns:
            Tuple of (allowed: bool, retry_after_seconds: int)
        
        Contract:
            - Limit: 3 attempts per hour per IP
            - Key: register_rate:{ip}
            - Window: 60 minutes
        """
    
    def record_login_attempt(
        self,
        ip_address: str,
        email: str,
        success: bool
    ) -> None:
        """
        Record a login attempt.
        
        Args:
            ip_address: Client IP address
            email: Email used in login attempt
            success: True if login succeeded, False if failed
        
        Contract:
            - If success=True, counter is reset
            - If success=False, counter is incremented with 15-min TTL
        """
    
    def record_register_attempt(
        self,
        ip_address: str
    ) -> None:
        """
        Record a registration attempt.
        
        Args:
            ip_address: Client IP address
        
        Contract:
            - Increments counter with 60-minute TTL
        """
Configuration:

# Rate limit constants
LOGIN_LIMIT = 5
LOGIN_WINDOW_SECONDS = 900  # 15 minutes
REGISTER_LIMIT = 3
REGISTER_WINDOW_SECONDS = 3600  # 1 hour
PasswordValidator
Module: app/services/validators.py

Public Methods:

class PasswordValidator:
    def validate(
        self,
        password: str
    ) -> bool:
        """
        Validate password meets complexity requirements.
        
        Args:
            password: Password to validate
        
        Returns:
            True if valid, False otherwise
        """
    
    def get_validation_errors(
        self,
        password: str
    ) -> List[str]:
        """
        Get list of validation errors for password.
        
        Args:
            password: Password to validate
        
        Returns:
            List of error codes (e.g., ["min_8_chars", "missing_uppercase"])
        
        Contract:
            - Empty list means valid password
        """
Validation Rules:

Minimum 8 characters
At least 1 uppercase letter (A-Z)
At least 1 lowercase letter (a-z)
At least 1 digit (0-9)
At least 1 special character (!@#$%^&*)
EmailValidator
Module: app/services/validators.py

Public Methods:

class EmailValidator:
    def validate(
        self,
        email: str
    ) -> bool:
        """
        Validate email format.
        
        Args:
            email: Email address to validate
        
        Returns:
            True if valid RFC 5322 format, False otherwise
        
        Contract:
            - Uses email-validator library
            - Max 255 characters
        """
Data Schemas
PostgreSQL Tables
users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
Roles:

user: Standard authenticated user
admin: Administrative access to all endpoints
revoked_tokens
CREATE TABLE revoked_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_jti VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    revoked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_revoked_tokens_jti ON revoked_tokens(token_jti);
CREATE INDEX idx_revoked_tokens_expires ON revoked_tokens(expires_at);
CREATE INDEX idx_revoked_tokens_user_id ON revoked_tokens(user_id);
Purpose: Track revoked refresh tokens for logout and token rotation.

Cleanup: Periodic job (daily) to delete expired entries where expires_at < NOW().

JWT Token Structure
Access Token Claims
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "role": "user",
  "exp": 1708046629,
  "iat": 1708045729,
  "type": "access"
}
Claims:

sub: User ID (UUID)
role: User role (user/admin)
exp: Expiration timestamp (Unix epoch)
iat: Issued at timestamp
type: Token type identifier
Signature: HS256 with secret key (RS256 recommended for production)

Refresh Token Claims
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "jti": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "exp": 1708650529,
  "iat": 1708045729,
  "type": "refresh"
}
Claims:

sub: User ID (UUID)
jti: JWT ID (unique identifier for token revocation)
exp: Expiration timestamp (7 days from issuance)
iat: Issued at timestamp
type: Token type identifier
Security and Privacy
1. Password Security
Hashing Algorithm: Argon2id (OWASP recommended)

Configuration:

from passlib.hash import argon2

# Argon2 parameters
scheme = argon2.using(
    type="ID",              # Argon2id variant
    time_cost=2,            # Iterations
    memory_cost=102400,     # 100 MB
    parallelism=8,          # Threads
    hash_len=32,            # Output hash length
    salt_len=16             # Salt length
)
Best Practices:

Never log passwords (even hashed)
Use constant-time comparison for password verification
Enforce password complexity requirements (validated client and server-side)
Consider password strength meter in UI (e.g., zxcvbn)
2. Token Security
Access Token:

TTL: 15 minutes
Short-lived to limit exposure window
Contains minimal claims (user_id, role)
Refresh Token:

TTL: 7 days
Rotation on each refresh (old token revoked)
Stored in revoked_tokens table on logout
Longer TTL for better UX, but revocable
JWT Signing:

MVP: HS256 with 256-bit secret key
Production: RS256 with 2048-bit RSA key pair
Store signing keys in environment variables, never in code
Token Validation:

Verify signature
Check expiration (exp claim)
For refresh tokens: Check if JTI in revoked_tokens table
Verify token type matches endpoint (access vs refresh)
3. Rate Limiting
Login Rate Limiting
Limit: 5 attempts per 15 minutes per IP address
Scope: Per email + IP combination
Lockout: Progressive delays (1s, 2s, 5s, 10s, 30s)
Reset: Counter resets after 15 minutes or successful login
Registration Rate Limiting
Limit: 3 attempts per hour per IP address
Scope: IP-based only
Purpose: Prevent bulk account creation
Implementation:

MVP: In-memory dictionary with TTL
Production: Redis with INCR + EXPIRE commands
Rate Limit Response Headers:

X-RateLimit-Limit: 5
X-RateLimit-Remaining: 2
X-RateLimit-Reset: 1708046629
Retry-After: 900
4. Platform-Specific Security
Web
CSRF Protection:

Double-submit cookie pattern
CSRF token generated on login/register
Token stored in non-HttpOnly cookie + sent in X-CSRF-Token header
Backend validates token match on mutation requests
Cookie Configuration:

response.set_cookie(
    key="access_token",
    value=access_token,
    httponly=True,           # No JS access
    secure=True,             # HTTPS only
    samesite="Strict",       # CSRF protection
    max_age=900,             # 15 minutes
    path="/"
)
CORS Settings:

Allowed origins: Production domains only (whitelist)
Allow credentials: True
Preflight caching: 1 hour
Mobile
Secure Storage:

Use flutter_secure_storage package
Fallback: Encrypted SharedPreferences if secure storage unavailable
Never store tokens in plain text SharedPreferences or files
Certificate Pinning (Future Enhancement):

Pin API server SSL certificate
Prevents man-in-the-middle attacks
Biometric Authentication (Future Enhancement):

Store refresh token behind biometric lock
Require Face ID/Touch ID before accessing tokens
5. Authorization
Role-Based Access Control (RBAC):

user role: Access to /api/chat/query with own conversations
admin role: Access to /admin/* endpoints (document management, user analytics)
Authorization Middleware:

async def require_role(required_role: str):
    """Dependency to enforce role-based access"""
    current_user = Depends(get_current_user)
    if current_user.role != required_role:
        raise HTTPException(403, detail={"error_code": "FORBIDDEN"})
    return current_user
Endpoint Protection:

/api/chat/query: Optional auth (guest or authenticated)
/auth/logout: Requires valid access token
/admin/*: Requires access token + admin role
6. Data Protection
Transport Security:

HTTPS only (TLS 1.2+)
HSTS header: Strict-Transport-Security: max-age=31536000; includeSubDomains
No mixed content (all assets served over HTTPS)
Database Security:

Encrypted connections (SSL/TLS) to PostgreSQL
Principle of least privilege (app user has minimal permissions)
Regular backups with encryption at rest
Logging Security:

Never log:
Passwords (plain or hashed)
Tokens (access or refresh)
Full request bodies containing sensitive data
Log only:
User IDs
Timestamps
Success/failure status
Error types (not error details with PII)
Example Secure Log Entry:

{
  "timestamp": "2026-02-15T22:30:00Z",
  "level": "INFO",
  "event": "user_login",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "ip": "192.168.1.100",
  "status": "success"
}
Testing Strategy
Unit Tests
AuthService Tests
test_register_success: Valid email/password creates user
test_register_duplicate_email: Returns EMAIL_ALREADY_EXISTS
test_register_weak_password: Returns VALIDATION_ERROR
test_login_success: Valid credentials return tokens
test_login_invalid_password: Returns INVALID_CREDENTIALS
test_login_nonexistent_email: Returns INVALID_CREDENTIALS
test_refresh_success: Valid refresh token returns new tokens
test_refresh_revoked_token: Returns INVALID_REFRESH_TOKEN
test_refresh_expired_token: Returns INVALID_REFRESH_TOKEN
test_logout_success: Adds refresh token to revoked list
test_password_hashing: Verify Argon2 parameters
test_token_generation: Verify JWT claims structure
PasswordValidator Tests
test_valid_password: Meets all requirements
test_too_short: < 8 characters
test_no_uppercase: Missing uppercase letter
test_no_lowercase: Missing lowercase letter
test_no_digit: Missing digit
test_no_special_char: Missing special character
RateLimiter Tests
test_login_rate_limit: Blocks after 5 attempts
test_registration_rate_limit: Blocks after 3 attempts
test_rate_limit_reset: Counter resets after TTL
test_successful_login_resets_counter: Rate limit cleared on success
Integration Tests
API Endpoint Tests
test_register_endpoint_web: Returns cookies + CSRF token
test_register_endpoint_mobile: Returns tokens in body
test_login_endpoint_web: Sets cookies correctly
test_login_endpoint_mobile: Returns tokens correctly
test_refresh_endpoint_web: Reads cookie, returns new tokens
test_refresh_endpoint_mobile: Reads body token, returns new tokens
test_logout_endpoint: Revokes token and clears cookies
test_csrf_protection: Rejects requests without CSRF token
test_cors_configuration: Allows whitelisted origins only
E2E Tests
Web Flow
User registers → redirected to authenticated mode
User logs out → tokens cleared, redirected to guest mode
User logs in → authenticated mode restored
Access token expires → automatic refresh
Refresh token expires → redirected to login
Mobile Flow
User registers → tokens stored in secure storage
App restart → tokens restored, authenticated mode
User logs out → tokens deleted
Token refresh during API call → interceptor handles seamlessly
Load/Security Tests
Rate Limit Enforcement: Simulate brute force attacks
Token Revocation: Verify revoked tokens are rejected
Concurrent Refresh Attempts: Test race conditions
CSRF Attack Simulation: Verify CSRF protection works
SQL Injection: Test with malicious email inputs
XSS Attempts: Test with script injection in email field
Implementation Checklist
Phase 1: Core Authentication (Week 1)

Set up PostgreSQL tables (users, revoked_tokens)

Implement AuthService with password hashing (Argon2)

Implement JWT token generation and validation

Create /auth/register endpoint

Create /auth/login endpoint

Write unit tests for AuthService

Write integration tests for registration/login endpoints
Phase 2: Token Management (Week 1)

Implement token refresh logic with rotation

Create /auth/refresh endpoint

Implement token revocation in revoked_tokens table

Create /auth/logout endpoint

Write unit tests for refresh/logout

Write integration tests for token lifecycle
Phase 3: Web-Specific Features (Week 2)

Implement HttpOnly cookie handling

Implement CSRF token generation and validation

Configure CORS for production domains

Test CSRF protection with Postman/curl

Write E2E tests for web authentication flow
Phase 4: Mobile-Specific Features (Week 2)

Integrate flutter_secure_storage in Flutter app

Implement token storage/retrieval

Create dio interceptor for token refresh

Handle 401 errors with automatic retry

Test on iOS and Android devices

Write E2E tests for mobile authentication flow
Phase 5: Rate Limiting (Week 3)

Implement RateLimiter service (in-memory for MVP)

Add rate limiting to /auth/login (5/15min)

Add rate limiting to /auth/register (3/hour)

Add rate limit headers to responses

Write unit tests for RateLimiter

Test rate limit enforcement
Phase 6: Validation & Security (Week 3)

Implement PasswordValidator with complexity rules

Implement EmailValidator (RFC 5322)

Add input sanitization for XSS prevention

Configure secure headers (HSTS, CSP)

Audit logging configuration (no sensitive data)

Security code review
Phase 7: Production Readiness (Week 4)

Migrate rate limiting to Redis (for multi-instance)

Set up periodic cleanup job for revoked_tokens

Load testing (100 concurrent users)

Penetration testing (OWASP Top 10)

Document API in OpenAPI/Swagger

Create deployment guide with environment variables
Success Criteria
✅ Users can register with email/password and receive JWT tokens
✅ Users can login with valid credentials
✅ Access tokens expire after 15 minutes
✅ Refresh tokens work correctly and rotate on each use
✅ Logout revokes refresh tokens
✅ Web: Tokens stored in HttpOnly cookies with CSRF protection
✅ Mobile: Tokens stored in secure storage (Keychain/KeyStore)
✅ Rate limiting prevents brute force attacks
✅ All passwords hashed with Argon2
✅ 100% unit test coverage for AuthService
✅ E2E tests pass on web and mobile (iOS/Android)
✅ No sensitive data logged
Risks to Completion
Edge cases around token expiry and refresh across platforms

Mitigation: Comprehensive E2E tests for token lifecycle on web and mobile
Test Plan: Simulate access token expiry during active session, verify auto-refresh
CSRF and CORS configuration errors

Mitigation: Use well-tested CORS/CSRF middleware, follow FastAPI security best practices
Test Plan: Manual testing with cross-origin requests, automated CSRF attack simulation
Token storage security on mobile

Mitigation: Use flutter_secure_storage, fallback to encrypted SharedPreferences
Test Plan: Test on rooted/jailbroken devices, verify encryption at rest
Handling expired tokens during active sessions

Mitigation: Implement dio interceptor with automatic refresh and request retry
Test Plan: Expire access token mid-session, verify seamless refresh without UX disruption
Race conditions during concurrent token refresh

Mitigation: Lock refresh requests in interceptor, queue concurrent API calls
Test Plan: Simulate 10 concurrent API calls with expired token, verify single refresh call
Rate limit bypass via distributed IPs

Mitigation: Combine IP + email rate limiting, implement progressive delays
Test Plan: Simulate attacks from multiple IPs, verify email-based rate limiting works
Story Status: Ready for Implementation
Estimated Effort: 4 weeks (1 backend developer + 1 frontend developer)
Dependencies: PostgreSQL database setup, Flutter project initialized
Next Steps: Begin Phase 1 (Core Authentication)

