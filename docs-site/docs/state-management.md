# State Management & Flows

Our application uses **Riverpod** for state management, following an asynchronous, notifier-based pattern.

## Authentication State Machine

The `AuthController` manages the global authentication lifecycle.

```mermaid
stateDiagram-v2
    [*] --> Initializing
    Initializing --> Guest: No tokens found
    Initializing --> Authenticated: Valid tokens loaded
    Initializing --> SessionExpired: Expired tokens / Refresh failed
    
    Guest --> Authenticated: Successful Login/Register
    Authenticated --> Guest: User Logout
    Authenticated --> SessionExpired: API returns 401 & Refresh fails
    
    SessionExpired --> Authenticated: New Login
    SessionExpired --> Guest: Continue as Guest
```

## Chat Query Flow

The following diagram illustrates the lifecycle of a single query, including guest rate limiting logic.

```mermaid
sequenceDiagram
    participant U as User
    participant C as ChatController
    participant R as ChatRepository
    participant B as Backend
    
    U->>C: sendMessage(text)
    C->>C: Add user message to local state
    C->>R: sendQuery(text)
    
    alt Guest Mode
        R->>B: POST /api/chat/query (guest_session_id)
        alt Rate Limit Exceeded
            B-->>R: 429 Error
            R-->>C: RateLimitException
            C->>C: Show RateLimit Modal
        else Success
            B-->>R: 200 OK (Answer + Remaining)
            R-->>C: AnswerResult
            C->>C: Update messages & count
        end
    else Authenticated
        R->>B: POST /api/chat/query (JWT)
        B-->>R: 200 OK (Answer)
        R-->>C: AnswerResult
        C->>C: Update messages & history
    end
```

## Provider Dependency Graph

Riverpod enforces a clear dependency directional flow:

```mermaid
graph BT
    Router[AppRouter] --> AuthC[AuthController]
    AuthC --> AuthR[AuthRepository]
    ChatC[ChatController] --> ChatR[ChatRepository]
    ChatR --> Dio[DioProvider]
    AuthR --> Dio
    Dio --> Interceptor[HttpInterceptor]
```
