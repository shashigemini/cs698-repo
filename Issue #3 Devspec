# Header

As a commuter, I want to access the chat interface via a responsive mobile web or native view so that I can consume the content on the go instead of carrying physical books.

---

# Architecture Diagram

```mermaid
flowchart LR
    subgraph Client["Flutter App"]
        S["Startup Logic"]
        AUIS["Auth Screens<br/>(guest/login/register)"]
        CH["Chat Screen<br/>(Guest + Auth)"]
        LS["StorageService<br/>(tokens & guest_session_id)"]
        INT["HTTP Interceptor<br/>(token refresh)"]
    end

    subgraph Backend["FastAPI API"]
        AUTH["/Auth endpoints/"]
        CHAT["/POST /api/chat/query/"]
    end

    S --> LS
    S --> AUIS
    AUIS --> AUTH
    AUIS --> CH
    CH --> INT
    INT --> CHAT
    INT --> AUTH
    LS --- AUIS
    LS --- CH
    LS --- INT
```

## Where Components Run

- **Flutter**: Single codebase built for web, iOS, Android
- **Backend**: Same FastAPI APIs as in Stories 1 and 2
- **Deployment**:
  - **Web**: Hosted on CDN/static hosting, HTTPS required
  - **iOS**: App Store distribution
  - **Android**: Google Play Store distribution

## Information Flows

### App Startup Flow
1. User opens app (web/iOS/Android)
2. **StartupScreen** displays loading indicator
3. **StorageService** attempts to load tokens:
   - **Web**: Checks HttpOnly cookies (automatic), reads CSRF token from localStorage
   - **Mobile**: Reads from flutter_secure_storage
4. If valid access token found:
   - Verify token not expired (check `exp` claim)
   - If expired, attempt refresh via `/auth/refresh`
   - On refresh success: Navigate to **ChatScreen** (authenticated mode)
   - On refresh failure: Navigate to **AuthScreen** (guest mode)
5. If no valid token:
   - Load or generate `guest_session_id` (UUID v4)
   - Navigate to **AuthScreen** with option to continue as guest

### Guest Mode Flow
1. User selects "Continue as Guest"
2. **StorageService** generates UUID v4 if not exists, saves to:
   - **Web**: localStorage
   - **Mobile**: SharedPreferences (not secure storage, as it's not sensitive)
3. Navigate to **ChatScreen** with guest banner:
   - Banner text: "You're using guest mode. X queries remaining today. Sign in for unlimited access."
   - Banner includes "Sign In" button
4. User types query and sends
5. **ChatRepository** calls `/api/chat/query` with:
   - `guest_session_id`: UUID from storage
   - `conversation_id`: null
   - No Authorization header
6. On success:
   - Display answer and citations
   - Update remaining queries from rate limit response (if provided)
7. On `RATE_LIMIT_EXCEEDED` error:
   - Show modal: "You've reached your daily limit (10 queries). Sign in for unlimited access."
   - Disable input field, show "Sign In" button

### Authentication Flow
1. User clicks "Sign In" or "Register" from guest mode
2. Navigate to **AuthScreen** (Login/Register tabs)
3. User enters email and password
4. **AuthRepository** calls `/auth/login` or `/auth/register`
5. On success:
   - **Web**: Server sets HttpOnly cookies, client saves CSRF token to localStorage
   - **Mobile**: Client saves tokens to flutter_secure_storage
   - Update **AuthController** state to `authenticated`
   - Navigate to **ChatScreen** (authenticated mode)
6. On error:
   - Display error message below form
   - For `EMAIL_ALREADY_EXISTS`: "This email is already registered. Try logging in."
   - For `INVALID_CREDENTIALS`: "Invalid email or password. Please try again."
   - For `RATE_LIMIT_EXCEEDED`: "Too many attempts. Please try again in X minutes."

### Authenticated Chat Flow
1. **ChatScreen** loads conversation history (if `conversation_id` exists)
2. User types query and sends
3. **ChatRepository** calls `/api/chat/query` with:
   - Authorization header: `Bearer <access_token>`
   - `conversation_id`: UUID (or null for new conversation)
   - `guest_session_id`: null
4. **HTTP Interceptor** checks token expiry before request:
   - If `exp` claim < current time + 60 seconds, trigger refresh
   - Lock concurrent requests during refresh
   - On refresh success: Update stored tokens, retry request
   - On refresh failure: Clear tokens, navigate to login
5. On 401 response:
   - Attempt token refresh
   - If refresh succeeds: Retry original request
   - If refresh fails: Clear tokens, navigate to login with message "Your session expired. Please log in again."
6. On success:
   - Display answer and citations
   - Save `conversation_id` for next query
   - No banner displayed (full access)

### Logout Flow
1. User clicks logout button (in app drawer/menu)
2. Show confirmation dialog: "Are you sure you want to log out?"
3. On confirm:
   - **AuthRepository** calls `/auth/logout` with access token
   - **StorageService** clears all tokens:
     - **Web**: Server clears cookies, client clears localStorage CSRF token
     - **Mobile**: Delete tokens from flutter_secure_storage
   - Update **AuthController** state to `guest`
   - Navigate to **AuthScreen** with guest option

---

# Class Diagram

```mermaid
classDiagram
    class AuthRepository {
        +Dio httpClient
        +Future~TokenPair~ login(email, password)
        +Future~TokenPair~ register(email, password)
        +Future~TokenPair~ refresh(refreshToken)
        +Future~void~ logout()
    }

    class ChatRepository {
        +Dio httpClient
        +Future~AnswerResult~ sendQuery(query, conversationId?, guestSessionId?)
        +Future~List~Message~~ getConversationHistory(conversationId)
    }

    class AuthController {
        +AuthState state
        +StorageService storage
        +AuthRepository repository
        +Future~void~ init()
        +Future~void~ login(email, password)
        +Future~void~ register(email, password)
        +Future~void~ logout()
        +Future~bool~ refreshToken()
    }

    class ChatController {
        +ChatState state
        +StorageService storage
        +ChatRepository repository
        +Future~void~ sendMessage(text)
        +Future~void~ loadConversation(conversationId)
        +void setConversationId(id)
    }

    class StorageService {
        +FlutterSecureStorage secureStorage
        +SharedPreferences prefs
        +Future~void~ saveTokens(TokenPair)
        +Future~TokenPair?~ loadTokens()
        +Future~void~ clearTokens()
        +Future~void~ saveGuestSessionId(string)
        +Future~string?~ loadGuestSessionId()
        +Future~void~ saveCsrfToken(string)
        +Future~string?~ loadCsrfToken()
        +Future~void~ saveConversationId(string)
        +Future~string?~ loadConversationId()
    }

    class HttpInterceptor {
        +StorageService storage
        +AuthController authController
        +Future~void~ onRequest(options, handler)
        +Future~void~ onResponse(response, handler)
        +Future~void~ onError(error, handler)
        +Future~bool~ refreshTokenIfNeeded()
    }

    class TokenPair {
        +string accessToken
        +string refreshToken
        +DateTime accessExpiresAt
        +DateTime refreshExpiresAt
    }

    class Message {
        +string id
        +string sender
        +string content
        +List~Citation~ citations
        +DateTime timestamp
    }

    class AnswerResult {
        +string answer
        +List~Citation~ citations
        +string? conversationId
        +Map? metadata
    }

    class Citation {
        +string documentId
        +string title
        +int page
        +string paragraphId
        +float relevanceScore
    }

    class AuthState {
        +AuthStatus status
        +User? user
        +String? error
        +bool isLoading
    }

    class ChatState {
        +List~Message~ messages
        +bool isLoading
        +String? error
        +String? conversationId
        +int? remainingGuestQueries
        +bool isGuest
    }

    AuthController --> AuthRepository
    ChatController --> ChatRepository
    AuthController --> StorageService
    ChatController --> StorageService
    HttpInterceptor --> StorageService
    HttpInterceptor --> AuthController
    AuthRepository --> TokenPair
    ChatRepository --> AnswerResult
    AnswerResult --> Citation
    ChatState --> Message
    Message --> Citation
```

---

# List of Classes

## Repository Layer (Data Access)
- **AuthRepository**: HTTP calls to `/auth/*` endpoints
- **ChatRepository**: HTTP calls to `/api/chat/query`

## Controller/State Management Layer
- **AuthController**: Manages authentication state (Riverpod StateNotifier or Bloc)
- **ChatController**: Manages chat state and message list

## Service Layer
- **StorageService**: Platform-specific storage abstraction (cookies, secure storage, SharedPreferences)
- **HttpInterceptor**: dio interceptor for automatic token refresh and error handling

## Model Layer
- **TokenPair**: Access and refresh tokens with expiry timestamps
- **Message**: Chat message (user or assistant) with citations
- **AnswerResult**: API response from `/api/chat/query`
- **Citation**: Document citation with page and relevance
- **AuthState**: Authentication state (guest/authenticated/loading)
- **ChatState**: Chat UI state (messages, loading, errors)

## UI Layer (Screens)
- **StartupScreen**: Initial loading screen with token validation
- **AuthScreen**: Login/Register with guest option
- **ChatScreen**: Main chat interface (guest and authenticated modes)
- **ConversationHistoryScreen**: List of past conversations (authenticated only)

---

# State Diagrams

## Authentication State Machine

```mermaid
stateDiagram-v2
    [*] --> Initializing

    Initializing --> LoadingTokens : App startup
    LoadingTokens --> ValidatingTokens : Tokens found
    LoadingTokens --> Guest : No tokens

    ValidatingTokens --> Authenticated : Valid access token
    ValidatingTokens --> RefreshingToken : Expired access token
    ValidatingTokens --> Guest : No refresh token

    RefreshingToken --> Authenticated : Refresh success
    RefreshingToken --> Guest : Refresh failure

    Guest --> Registering : User clicks register
    Guest --> LoggingIn : User clicks login
    Guest --> Guest : Send guest query (limited)

    Registering --> Authenticated : Registration success
    Registering --> Guest : Registration cancelled
    Registering --> Error : Registration failed

    LoggingIn --> Authenticated : Login success
    LoggingIn --> Guest : Login cancelled
    LoggingIn --> Error : Login failed

    Error --> Guest : Dismiss error
    Error --> Registering : Retry registration
    Error --> LoggingIn : Retry login

    Authenticated --> RefreshingToken : Token expires
    Authenticated --> LoggingOut : User clicks logout

    LoggingOut --> Guest : Logout complete

    note right of RefreshingToken
        Automatic refresh happens:
        - 60s before expiry
        - On 401 response
    end note

    note right of Guest
        Guest mode persists
        guest_session_id
        for rate limiting
    end note
```

## Chat Flow State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> SendingQuery : User sends message
    SendingQuery --> WaitingForResponse : Request sent
    WaitingForResponse --> DisplayingAnswer : Response received
    WaitingForResponse --> Error : Request failed

    DisplayingAnswer --> Idle : Answer displayed

    Error --> Idle : Dismiss error
    Error --> SendingQuery : Retry

    Idle --> RateLimitReached : Guest limit exceeded
    RateLimitReached --> Idle : User signs in

    Idle --> LoadingHistory : Load conversation (auth only)
    LoadingHistory --> Idle : History loaded
    LoadingHistory --> Error : Load failed

    note right of SendingQuery
        Show typing indicator
        Disable input field
    end note

    note right of RateLimitReached
        Show modal with
        "Sign in" button
    end note
```

---

# Flow Chart (Complete Startup to Chat)

```mermaid
flowchart TD
    START([User opens app]) --> SPLASH[StartupScreen]
    SPLASH --> LOAD[StorageService.loadTokens]

    LOAD --> HAS_TOKENS{Tokens exist?}
    HAS_TOKENS -->|No| LOAD_GUEST[Load guest_session_id]
    HAS_TOKENS -->|Yes| CHECK_EXP{Access token expired?}

    CHECK_EXP -->|No| AUTH_MODE[Navigate to ChatScreen<br/>Authenticated]
    CHECK_EXP -->|Yes| REFRESH[Call /auth/refresh]

    REFRESH --> REFRESH_OK{Refresh success?}
    REFRESH_OK -->|Yes| SAVE_NEW[Save new tokens]
    SAVE_NEW --> AUTH_MODE
    REFRESH_OK -->|No| CLEAR[Clear invalid tokens]
    CLEAR --> LOAD_GUEST

    LOAD_GUEST --> HAS_GUEST{guest_session_id exists?}
    HAS_GUEST -->|No| GEN_GUEST[Generate UUID v4]
    GEN_GUEST --> SAVE_GUEST[Save guest_session_id]
    HAS_GUEST -->|Yes| GUEST_MODE[Navigate to AuthScreen<br/>with guest option]
    SAVE_GUEST --> GUEST_MODE

    GUEST_MODE --> USER_CHOICE{User action?}
    USER_CHOICE -->|Continue as Guest| GUEST_CHAT[ChatScreen<br/>Guest Mode]
    USER_CHOICE -->|Sign In| LOGIN_FORM[Login Form]
    USER_CHOICE -->|Register| REG_FORM[Register Form]

    LOGIN_FORM --> SUBMIT_LOGIN[POST /auth/login]
    SUBMIT_LOGIN --> LOGIN_OK{Login success?}
    LOGIN_OK -->|Yes| SAVE_TOKENS[Save tokens]
    SAVE_TOKENS --> AUTH_MODE
    LOGIN_OK -->|No| SHOW_ERR1[Show error message]
    SHOW_ERR1 --> LOGIN_FORM

    REG_FORM --> SUBMIT_REG[POST /auth/register]
    SUBMIT_REG --> REG_OK{Register success?}
    REG_OK -->|Yes| SAVE_TOKENS
    REG_OK -->|No| SHOW_ERR2[Show error message]
    SHOW_ERR2 --> REG_FORM

    GUEST_CHAT --> GUEST_INPUT[User types query]
    GUEST_INPUT --> GUEST_SEND[POST /api/chat/query<br/>with guest_session_id]
    GUEST_SEND --> GUEST_RESP{Response status?}
    GUEST_RESP -->|200 OK| DISPLAY1[Display answer]
    GUEST_RESP -->|429 Rate Limit| RATE_MODAL[Show rate limit modal]
    GUEST_RESP -->|Other Error| ERR_MSG1[Show error toast]

    RATE_MODAL --> PROMPT_LOGIN[Prompt to sign in]
    PROMPT_LOGIN --> LOGIN_FORM

    DISPLAY1 --> GUEST_CHAT
    ERR_MSG1 --> GUEST_CHAT

    AUTH_MODE --> AUTH_INPUT[User types query]
    AUTH_INPUT --> CHECK_TOKEN{Token valid?}
    CHECK_TOKEN -->|No| REFRESH
    CHECK_TOKEN -->|Yes| AUTH_SEND[POST /api/chat/query<br/>with JWT]

    AUTH_SEND --> AUTH_RESP{Response status?}
    AUTH_RESP -->|200 OK| DISPLAY2[Display answer + save conversation_id]
    AUTH_RESP -->|401 Unauthorized| REFRESH
    AUTH_RESP -->|Other Error| ERR_MSG2[Show error toast]

    DISPLAY2 --> AUTH_MODE
    ERR_MSG2 --> AUTH_MODE
```

---

# Development Risks and Failures

1. **Ensuring guest vs auth flows work identically across web, iOS, Android**
   - Risk: Platform-specific bugs (e.g., iOS Keychain access, Android KeyStore issues, web cookie policies)
   - Mitigation: Extensive testing on each platform, use platform-specific test devices, abstract storage behind StorageService interface

2. **Handling keyboard, scroll, and back button behavior on mobile**
   - Risk: Different UX expectations (iOS swipe back vs Android hardware back button, keyboard covering input)
   - Mitigation: Use Flutter's built-in WillPopScope, adjust padding when keyboard appears, test on real devices

3. **Token refresh integration with app lifecycle** (foreground/background)
   - Risk: App suspended mid-refresh, tokens expire while in background, multiple refresh attempts on resume
   - Mitigation: Implement locking mechanism in HttpInterceptor, queue requests during refresh, handle WidgetsBindingObserver for lifecycle events

4. **Responsive design challenges**
   - Risk: UI breaks on tablets, landscape mode, foldable devices, various web browser widths
   - Mitigation: Use LayoutBuilder and MediaQuery, test on multiple screen sizes, use adaptive widgets

5. **Network error handling**
   - Risk: Poor connectivity leads to timeouts, partial data, confusing error messages
   - Mitigation: Implement retry logic with exponential backoff, show clear error messages ("No internet connection" vs "Server error"), cache last successful response

6. **State management complexity**
   - Risk: Inconsistent state across controllers (e.g., AuthController shows authenticated but ChatController has stale guest_session_id)
   - Mitigation: Single source of truth for auth state, use Riverpod family providers or Bloc observers to sync state changes

7. **CSRF token handling on web**
   - Risk: CSRF token not sent with requests, mismatched token between server and client
   - Mitigation: Test CSRF flow explicitly, ensure interceptor adds X-CSRF-Token header to all mutation requests

8. **Deep linking and navigation state**
   - Risk: User shares conversation link, deep link fails to restore auth state
   - Mitigation: Implement proper deep linking with go_router or Navigator 2.0, handle auth checks in route guards

---

# Technology Stack

## Frontend Framework
- **Flutter 3.19+** (Dart 3.3+)
- **Channels**: Stable channel for production

## State Management
- **Riverpod 2.x** (recommended) or **Bloc 8.x**
- **Justification**: Both support async operations, provide good DevTools, and handle complex state dependencies

## HTTP Client
- **dio 5.x**: Rich interceptor support, request/response transformation, timeout handling
- **Configuration**:
  ```dart
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  ```

## Storage
### Mobile (iOS/Android)
- **flutter_secure_storage 9.x**: Keychain (iOS), KeyStore (Android) for tokens
- **shared_preferences 2.x**: Non-sensitive data (guest_session_id, conversation_id)

### Web
- **Cookies**: HttpOnly cookies managed by browser (access/refresh tokens)
- **universal_html**: Access localStorage for CSRF token and guest_session_id
- **js**: Direct JavaScript interop if needed

## UI Components
- **flutter_markdown 0.6.x**: Render formatted text in answers
- **url_launcher 6.x**: Open citation links to documents
- **loading_animation_widget 1.x**: Loading indicators
- **fluttertoast 8.x**: Error/success toasts

## Routing
- **go_router 13.x** (recommended) or **auto_route 7.x**
- **Deep linking**: Handle `/chat/:conversationId` routes

## DevTools
- **flutter_lints 3.x**: Linting rules
- **flutter_test**: Unit and widget testing
- **integration_test**: E2E testing

---

# APIs / Public Interfaces

## Consumed REST APIs (External)

> **Purpose**: This story **consumes** backend APIs defined in Stories 1 and 2. The Flutter app acts as a client that makes HTTP requests to these existing endpoints.

### From Story 2 (Authentication APIs)

The Flutter app calls these authentication endpoints:

- **POST `/auth/register`**: Create new user account
- **POST `/auth/login`**: Authenticate user
- **POST `/auth/refresh`**: Refresh access token
- **POST `/auth/logout`**: Logout and revoke tokens

**Refer to Story 2 for complete API specifications** (request/response schemas, error codes, etc.)

---

### From Story 1 (Chat API)

The Flutter app calls this chat endpoint:

- **POST `/api/chat/query`**: Submit query and receive AI answer with citations

**Refer to Story 1 for complete API specifications** (request/response schemas, error codes, etc.)

---

## Error Handling Strategy

All API errors follow the global format defined in Stories 1 and 2:

```json
{
  "error_code": "SOME_CODE",
  "message": "Human readable message",
  "details": { "field": "...", "..." }
}
```

### Error Code Mapping to UI Messages

| Error Code | User-Facing Message | Action |
|------------|-------------------|--------|
| `INVALID_CREDENTIALS` | "Invalid email or password. Please try again." | Clear password field, keep email |
| `EMAIL_ALREADY_EXISTS` | "This email is already registered. Try logging in instead." | Show link to login tab |
| `VALIDATION_ERROR` | "Please check your input: [details]" | Highlight invalid field |
| `RATE_LIMIT_EXCEEDED` (Guest) | "You've reached your daily limit (10 queries). Sign in for unlimited access." | Show modal with "Sign In" button |
| `RATE_LIMIT_EXCEEDED` (Auth) | "Too many requests. Please try again in X minutes." | Display retry timer |
| `LOGIN_RATE_LIMIT_EXCEEDED` | "Too many login attempts. Please try again in X minutes." | Disable login button, show timer |
| `REGISTRATION_RATE_LIMIT_EXCEEDED` | "Too many registration attempts. Please try again later." | Disable register button |
| `UNAUTHORIZED` | "Your session expired. Please log in again." | Clear tokens, navigate to login |
| `INVALID_REFRESH_TOKEN` | "Your session expired. Please log in again." | Clear tokens, navigate to login |
| `QUERY_TOO_LONG` | "Your query is too long (max 2000 characters). Please shorten it." | Show character count, disable send |
| `LLM_ERROR` | "Our AI service is temporarily unavailable. Please try again shortly." | Show retry button |
| `RETRIEVAL_ERROR` | "Unable to search documents. Please try again." | Show retry button |
| `CONVERSATION_NOT_FOUND` | "This conversation no longer exists." | Clear conversation_id, reload |
| `FORBIDDEN` | "You don't have permission to access this." | Navigate to home |
| `INTERNAL_ERROR` | "Something went wrong on our end. Please try again." | Show retry button |
| `NETWORK_ERROR` (Client) | "No internet connection. Please check your network." | Show retry button |

### Network Error Handling

**Timeout Errors**:
```dart
if (error.type == DioExceptionType.connectTimeout) {
  return "Connection timeout. Please check your internet connection.";
}
```

**No Internet**:
```dart
if (error.type == DioExceptionType.unknown && 
    error.message.contains('SocketException')) {
  return "No internet connection. Please check your network settings.";
}
```

**Retry Logic**:
- Automatic retry for transient errors (503, timeout): Max 3 retries with exponential backoff (1s, 2s, 4s)
- User-initiated retry for all other errors via "Retry" button

---

## Public Interfaces (Internal Flutter Contracts)

> **Purpose**: Stable Dart classes and methods that define the internal architecture of the Flutter app. These are the contracts between different layers of the client application.

### StorageService (Platform Abstraction Layer)

**Module**: `lib/services/storage_service.dart`

**Responsibility**: Abstract platform-specific storage mechanisms (secure storage, SharedPreferences, localStorage, cookies).

**Public Methods**:

```dart
abstract class StorageService {
  /// Save authentication tokens to secure storage
  /// 
  /// Platform behavior:
  /// - iOS: Keychain (kSecAttrAccessibleAfterFirstUnlock)
  /// - Android: EncryptedSharedPreferences (KeyStore-backed)
  /// - Web: Tokens managed by HttpOnly cookies (no client storage)
  /// 
  /// Contract:
  /// - Overwrites existing tokens
  /// - Atomic operation (both tokens saved or neither)
  /// - Thread-safe
  Future<void> saveTokens(TokenPair tokens);
  
  /// Load authentication tokens from secure storage
  /// 
  /// Returns:
  /// - TokenPair if tokens exist
  /// - null if no tokens stored or storage access fails
  /// 
  /// Contract:
  /// - Does NOT validate token expiry (caller's responsibility)
  /// - Thread-safe
  Future<TokenPair?> loadTokens();
  
  /// Clear all authentication tokens
  /// 
  /// Contract:
  /// - Idempotent (safe to call multiple times)
  /// - Also clears CSRF token (web only)
  /// - Thread-safe
  Future<void> clearTokens();
  
  /// Save guest session ID to non-secure storage
  /// 
  /// Storage:
  /// - Mobile: SharedPreferences
  /// - Web: localStorage
  /// 
  /// Contract:
  /// - guest_session_id is not sensitive (rate limiting only)
  /// - Persists across app restarts
  /// - Cleared only on app uninstall or manual cache clear
  Future<void> saveGuestSessionId(String sessionId);
  
  /// Load guest session ID
  /// 
  /// Returns:
  /// - UUID string if exists
  /// - null if not set
  Future<String?> loadGuestSessionId();
  
  /// Save CSRF token (web only)
  /// 
  /// Contract:
  /// - No-op on mobile platforms
  /// - Stored in localStorage (not HttpOnly cookie)
  Future<void> saveCsrfToken(String token);
  
  /// Load CSRF token (web only)
  /// 
  /// Returns:
  /// - CSRF token string
  /// - null on mobile or if not set
  Future<String?> loadCsrfToken();
  
  /// Save last active conversation ID
  /// 
  /// Storage:
  /// - SharedPreferences (mobile)
  /// - localStorage (web)
  Future<void> saveConversationId(String conversationId);
  
  /// Load last active conversation ID
  Future<String?> loadConversationId();
}
```

**Implementation Classes**:
- `MobileStorageService`: Uses flutter_secure_storage + SharedPreferences
- `WebStorageService`: Uses universal_html (localStorage) + cookie APIs

**Factory Constructor**:
```dart
factory StorageService.create() {
  if (kIsWeb) {
    return WebStorageService();
  } else {
    return MobileStorageService();
  }
}
```

---

### AuthRepository (Data Layer)

**Module**: `lib/repositories/auth_repository.dart`

**Responsibility**: HTTP calls to authentication endpoints.

**Public Methods**:

```dart
class AuthRepository {
  final Dio _httpClient;
  
  /// Register a new user account
  /// 
  /// Returns:
  /// - TokenPair with access and refresh tokens
  /// 
  /// Throws:
  /// - EmailAlreadyExistsException: Email is registered
  /// - ValidationException: Invalid email or weak password
  /// - RateLimitException: Too many registration attempts
  /// - NetworkException: Connection failure
  Future<TokenPair> register(
    String email,
    String password
  );
  
  /// Authenticate user with email and password
  /// 
  /// Returns:
  /// - TokenPair with access and refresh tokens
  /// 
  /// Throws:
  /// - InvalidCredentialsException: Email or password wrong
  /// - RateLimitException: Too many login attempts
  /// - NetworkException: Connection failure
  Future<TokenPair> login(
    String email,
    String password
  );
  
  /// Refresh access token using refresh token
  /// 
  /// Args:
  /// - refreshToken: JWT refresh token (mobile only, web reads from cookie)
  /// 
  /// Returns:
  /// - New TokenPair with rotated refresh token
  /// 
  /// Throws:
  /// - InvalidRefreshTokenException: Token expired or revoked
  /// - NetworkException: Connection failure
  /// 
  /// Contract:
  /// - Old refresh token is invalidated server-side
  /// - Caller must replace old token with new token
  Future<TokenPair> refresh(String? refreshToken);
  
  /// Logout user and revoke refresh token
  /// 
  /// Contract:
  /// - Server revokes refresh token
  /// - Caller must clear local tokens after success
  /// - Idempotent (safe to retry)
  Future<void> logout();
}
```

---

### ChatRepository (Data Layer)

**Module**: `lib/repositories/chat_repository.dart`

**Responsibility**: HTTP calls to chat endpoints.

**Public Methods**:

```dart
class ChatRepository {
  final Dio _httpClient;
  
  /// Send a query to the RAG system
  /// 
  /// Args:
  /// - query: User question (1-2000 chars)
  /// - conversationId: UUID for continuing conversation (null for new)
  /// - guestSessionId: UUID for guest mode (null for authenticated)
  /// 
  /// Returns:
  /// - AnswerResult with answer, citations, and conversation_id
  /// 
  /// Throws:
  /// - ValidationException: Query too long or empty
  /// - RateLimitException: Guest limit reached
  /// - UnauthorizedException: Token expired (triggers refresh)
  /// - LLMException: AI service failure
  /// - NetworkException: Connection failure
  /// 
  /// Contract:
  /// - For authenticated users: conversation_id always returned
  /// - For guests: conversation_id is always null
  Future<AnswerResult> sendQuery(
    String query, {
    String? conversationId,
    String? guestSessionId,
  });
  
  /// Get conversation history (authenticated only)
  /// 
  /// Args:
  /// - conversationId: UUID of conversation to load
  /// 
  /// Returns:
  /// - List of Message objects (chronological order)
  /// 
  /// Throws:
  /// - ConversationNotFoundException: Conversation doesn't exist
  /// - UnauthorizedException: Not authenticated
  /// - NetworkException: Connection failure
  Future<List<Message>> getConversationHistory(
    String conversationId
  );
}
```

---

### HttpInterceptor (Middleware)

**Module**: `lib/interceptors/http_interceptor.dart`

**Responsibility**: Automatic token refresh, request/response transformation, error handling.

**Public Methods**:

```dart
class HttpInterceptor extends Interceptor {
  final StorageService _storage;
  final AuthController _authController;
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler
  ) async {
    // Add Authorization header if token exists
    // Add CSRF header for web mutation requests
    // Check token expiry and refresh if needed
  }
  
  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler
  ) async {
    // Transform API responses to Dart objects
    // Extract rate limit info from headers
  }
  
  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler
  ) async {
    // On 401: Attempt token refresh and retry
    // Map API error_codes to exceptions
    // Handle network errors gracefully
  }
  
  /// Refresh token if expiring soon or expired
  /// 
  /// Contract:
  /// - Acquires lock to prevent concurrent refreshes
  /// - Queues concurrent requests until refresh completes
  /// - On failure: Clears tokens and navigates to login
  Future<bool> refreshTokenIfNeeded();
}
```

---

### AuthController (State Management)

**Module**: `lib/controllers/auth_controller.dart`

**Responsibility**: Manage authentication state and coordinate auth operations.

**Public Methods**:

```dart
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService _storage;
  
  /// Initialize authentication state on app startup
  /// 
  /// Behavior:
  /// - Loads tokens from storage
  /// - Validates token expiry
  /// - Attempts refresh if needed
  /// - Sets initial state (authenticated or guest)
  Future<void> init();
  
  /// Login with email and password
  /// 
  /// Updates state:
  /// - isLoading: true during API call
  /// - status: authenticated on success
  /// - error: error message on failure
  Future<void> login(String email, String password);
  
  /// Register new account
  /// 
  /// Updates state:
  /// - isLoading: true during API call
  /// - status: authenticated on success
  /// - error: error message on failure
  Future<void> register(String email, String password);
  
  /// Logout current user
  /// 
  /// Behavior:
  /// - Calls logout API
  /// - Clears local tokens
  /// - Resets state to guest
  Future<void> logout();
  
  /// Refresh access token
  /// 
  /// Returns:
  /// - true if refresh succeeded
  /// - false if refresh failed (user must re-login)
  Future<bool> refreshToken();
}
```

---

### ChatController (State Management)

**Module**: `lib/controllers/chat_controller.dart`

**Responsibility**: Manage chat state and coordinate chat operations.

**Public Methods**:

```dart
class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final StorageService _storage;
  
  /// Send a message to the chat
  /// 
  /// Behavior:
  /// - Adds user message to state immediately
  /// - Calls API with query
  /// - Adds assistant response to state
  /// - Updates conversation_id and remaining queries
  Future<void> sendMessage(String text);
  
  /// Load conversation history (authenticated only)
  /// 
  /// Behavior:
  /// - Fetches messages from API
  /// - Replaces current message list
  /// - Sets conversation_id in state
  Future<void> loadConversation(String conversationId);
  
  /// Set active conversation ID
  /// 
  /// Used when starting a new conversation or switching conversations
  void setConversationId(String? id);
  
  /// Clear current conversation
  /// 
  /// Resets state to empty message list
  void clearConversation();
}
```

---

### Model Classes (Data Transfer Objects)

**Module**: `lib/models/`

```dart
/// Authentication token pair
@immutable
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
  
  /// Check if access token is expired or expiring soon
  bool get isAccessTokenExpired => 
    accessExpiresAt.isBefore(DateTime.now().add(Duration(seconds: 60)));
}

/// Chat message (user or assistant)
@immutable
class Message {
  final String id;
  final String sender;  // 'user' or 'assistant'
  final String content;
  final List<Citation> citations;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}

/// Answer result from RAG API
@immutable
class AnswerResult {
  final String answer;
  final List<Citation> citations;
  final String? conversationId;
  final Map<String, dynamic>? metadata;
}

/// Document citation
@immutable
class Citation {
  final String documentId;
  final String title;
  final int page;
  final String paragraphId;
  final double? relevanceScore;
}

/// Authentication state
@immutable
class AuthState {
  final AuthStatus status;  // initializing, guest, authenticated, error
  final User? user;
  final String? errorMessage;
  final bool isLoading;
}

/// Chat state
@immutable
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? errorMessage;
  final String? conversationId;
  final int? remainingGuestQueries;
  final bool isGuest;
}
```

---

# Data Schemas

## Client-Side Storage Schemas

### Mobile (flutter_secure_storage)

**Tokens** (Secure Storage):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "access_expires_at": "2026-02-15T22:15:00Z",
  "refresh_expires_at": "2026-02-22T22:00:00Z"
}
```

**Non-Sensitive Data** (SharedPreferences):
```json
{
  "guest_session_id": "550e8400-e29b-41d4-a716-446655440000",
  "last_conversation_id": "660e8400-e29b-41d4-a716-446655440000",
  "theme_mode": "dark",
  "has_seen_onboarding": true
}
```

---

### Web Storage

**HttpOnly Cookies** (Server-Managed, Not Accessible to JavaScript):
- `access_token`: JWT access token (15 min TTL)
- `refresh_token`: JWT refresh token (7 days TTL)

**localStorage** (Client-Managed):
```json
{
  "csrf_token": "a1b2c3d4e5f6...",
  "guest_session_id": "550e8400-e29b-41d4-a716-446655440000",
  "last_conversation_id": "660e8400-e29b-41d4-a716-446655440000",
  "theme_mode": "light"
}
```

**Note**: Never store tokens in localStorage on web (XSS vulnerability). Always use HttpOnly cookies.

---

# Security and Privacy

## 1. Token Storage Security

### Mobile (iOS/Android)
- ✅ **DO**: Store tokens in `flutter_secure_storage` (Keychain/KeyStore)
- ✅ **DO**: Store guest_session_id in SharedPreferences (not sensitive)
- ❌ **DON'T**: Store tokens in SharedPreferences or plain files
- ❌ **DON'T**: Log tokens in debug/release builds

**Implementation**:
```dart
final storage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
```

### Web
- ✅ **DO**: Use HttpOnly cookies for tokens (server-managed)
- ✅ **DO**: Store CSRF token in localStorage or in-memory state
- ❌ **DON'T**: Store access/refresh tokens in localStorage (XSS risk)
- ❌ **DON'T**: Store tokens in sessionStorage or regular cookies

**CSRF Token Handling**:
```dart
// Store CSRF token from login/register response
await _storageService.saveCsrfToken(csrfToken);

// Add to all mutation requests
final csrfToken = await _storageService.loadCsrfToken();
if (csrfToken != null) {
  options.headers['X-CSRF-Token'] = csrfToken;
}
```

---

## 2. Guest Session Privacy

- **guest_session_id**: Treated as opaque UUID for rate limiting only
- **Not logged**: Never log guest_session_id in analytics or crash reports
- **Regenerated**: New UUID on app reinstall or cache clear
- **No persistence backend**: Guest queries not saved to database

---

## 3. Network Security

### HTTPS Enforcement
```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',  // Always HTTPS
  validateStatus: (status) => status! < 500,
));
```

### Certificate Pinning (Production)
```dart
// Optional: Pin server SSL certificate
(_httpClient.httpClientAdapter as DefaultHttpClientAdapter)
    .onHttpClientCreate = (client) {
  client.badCertificateCallback = (cert, host, port) {
    return cert.sha1.toString() == expectedSha1;
  };
  return client;
};
```

### No Sensitive Data in URLs
- ❌ **DON'T**: `/api/chat/query?token=abc123`
- ✅ **DO**: Pass tokens in `Authorization` header

---

## 4. Input Validation & Sanitization

### Client-Side Validation

**Email**:
```dart
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return 'Email is required';
  }
  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!regex.hasMatch(email)) {
    return 'Invalid email format';
  }
  if (email.length > 255) {
    return 'Email too long (max 255 characters)';
  }
  return null;
}
```

**Password**:
```dart
String? validatePassword(String? password) {
  if (password == null || password.isEmpty) {
    return 'Password is required';
  }
  if (password.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password must contain an uppercase letter';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Password must contain a lowercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Password must contain a digit';
  }
  if (!RegExp(r'[!@#\$%\^\&\*]').hasMatch(password)) {
    return 'Password must contain a special character (!@#$%^&*)';
  }
  return null;
}
```

**Query Length**:
```dart
if (query.length > 2000) {
  return 'Query too long (max 2000 characters)';
}
if (query.trim().isEmpty) {
  return 'Query cannot be empty';
}
```

### XSS Prevention
- Use Flutter's built-in text rendering (no HTML injection risk)
- For markdown rendering: Use `flutter_markdown` with sanitization enabled
- Never use `dangerouslySetInnerHTML` equivalent

---

## 5. Logging & Crash Reporting

### What to Log
- ✅ User actions ("user_tapped_send_button")
- ✅ Navigation events ("navigated_to_chat_screen")
- ✅ API call success/failure counts
- ✅ Error types ("network_timeout", "invalid_response")

### What NOT to Log
- ❌ Tokens (access, refresh, CSRF)
- ❌ Passwords (plain or hashed)
- ❌ Full API request/response bodies (may contain PII)
- ❌ Email addresses in plain text (use hashed user_id instead)
- ❌ Query content (proprietary/sensitive questions)

**Example Secure Log**:
```dart
logger.info('User sent query', {
  'user_id': user.id,  // OK
  'query_length': query.length,  // OK
  'is_guest': isGuest,  // OK
  // NOT: 'query_content': query  // NEVER
});
```

---

## 6. Privacy Compliance

### Data Collection Disclosure
- **Guest Mode**: No personal data collected (guest_session_id is anonymous)
- **Authenticated Mode**: Email and query history stored
- **Analytics**: Opt-in only, no tracking without consent

### User Rights (GDPR/CCPA)
- **Right to Access**: Provide export of user's conversations
- **Right to Deletion**: Implement account deletion (cascade delete all data)
- **Right to Portability**: JSON export of chat history

---

# UI/UX Specifications

## Screen Layouts

### 1. StartupScreen
- **Layout**: Centered loading spinner + app logo
- **Duration**: 1-3 seconds (token validation)
- **No user interaction**: Non-dismissible loading state

---

### 2. AuthScreen

**Layout**:
- Toggle tabs: "Login" | "Register"
- Guest option at bottom: "Continue as Guest" button (secondary style)

**Login Tab**:
- Email input field
- Password input field (obscured, with show/hide toggle)
- "Login" button (primary)
- Error message area (red text below fields)
- "Forgot password?" link (future enhancement)

**Register Tab**:
- Email input field
- Password input field (obscured, with show/hide toggle)
- Password strength indicator (visual bar: weak/medium/strong)
- "Create Account" button (primary)
- Error message area
- "Already have an account? Login" link

**Guest Option**:
- Divider line with "OR"
- "Continue as Guest" button (outlined, secondary)
- Subtitle: "Limited to 10 queries per day"

---

### 3. ChatScreen (Guest Mode)

**Banner** (top, yellow background):
- Icon: ⚠️
- Text: "Guest Mode: X queries remaining today"
- Button: "Sign In" (right-aligned)

**Chat Area**:
- Message list (scrollable, reverse chronological)
  - User messages: Right-aligned, blue bubble
  - Assistant messages: Left-aligned, gray bubble
  - Citations: Small links below assistant message (e.g., "Source: Book Title, p. 42")
- Empty state: "Ask a question about our spiritual texts"

**Input Area** (bottom):
- Text field (multiline, max 4 lines before scroll)
- Character counter: "X / 2000"
- Send button (icon, disabled if empty or over limit)

**Rate Limit Modal** (when 10 queries reached):
- Title: "Daily Limit Reached"
- Body: "You've used all 10 guest queries today. Sign in for unlimited access to our knowledge base."
- Buttons: "Sign In" (primary), "Maybe Later" (secondary, closes modal)

---

### 4. ChatScreen (Authenticated Mode)

**No banner** (full screen for chat)

**App Drawer/Menu** (left):
- User info: Email display
- "New Conversation" button
- "Conversation History" (list of past conversations)
- "Logout" button (bottom)

**Chat Area**: Same as guest mode, but:
- Citations are clickable (open document viewer)
- Conversation history persists across sessions

**Input Area**: Same as guest mode, but:
- No character counter needed (optional)
- Send button always enabled (no rate limit)

---

## Responsive Design Breakpoints

| Breakpoint | Width | Layout Adjustments |
|------------|-------|--------------------|
| **Mobile** | < 600px | Single column, bottom navigation |
| **Tablet** | 600-1024px | Side panel for conversations (left) |
| **Desktop** | > 1024px | 3-column: drawer, chat, citations panel |

---

## Accessibility (a11y)

- **Semantic labels**: All buttons have accessible labels
- **Screen reader support**: Announce new messages
- **Keyboard navigation**: Tab order, Enter to send
- **High contrast mode**: Respect system dark/light mode
- **Font scaling**: Support system font size settings

---

# Risks to Completion

1. **UI/UX complexity around showing limits and transitions between guest/auth**
   - Mitigation: Create detailed wireframes, get UX feedback early, test with real users
   - Timeline Impact: +1 week if UX requires major revisions

2. **Tight coupling to backend error codes**
   - Mitigation: Document error code mapping, create shared schema with backend team, version API
   - Timeline Impact: +3 days if backend changes error format mid-development

3. **Platform-specific bugs** (iOS vs Android vs Web)
   - Mitigation: Test on real devices early, use platform channels sparingly, abstract platform differences
   - Timeline Impact: +1 week for debugging obscure platform issues

4. **Token refresh timing edge cases**
   - Mitigation: Comprehensive testing of token lifecycle, use proven interceptor pattern, handle race conditions
   - Timeline Impact: +3 days for edge case testing and fixes

5. **Testing complexity** (multiple platforms, screen sizes, network conditions)
   - Mitigation: Prioritize E2E tests for critical flows, use emulators/simulators for bulk testing, automate where possible
   - Timeline Impact: +1 week if E2E tests reveal major issues

6. **App store compliance** (iOS/Android review delays)
   - Mitigation: Follow platform guidelines strictly, test IAP/subscriptions (if added), prepare rejection response plan
   - Timeline Impact: +1 week if app rejected and resubmitted

7. **Performance issues on low-end devices**
   - Mitigation: Profile on low-end Android devices, optimize image sizes, lazy load conversation history
   - Timeline Impact: +3 days for performance optimization

---

**Story Status**: Ready for Implementation  
**Estimated Effort**: 6 weeks (1 Flutter developer)  
**Dependencies**: Stories 1 & 2 complete (backend APIs functional)  
**Deployment Targets**: Web (CDN), iOS App Store, Google Play Store  
**Next Steps**: Begin Phase 1 (Project Setup)