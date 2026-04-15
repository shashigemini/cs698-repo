---
title: "State Management"
sidebar_position: 4
---

# State Management & Flows

Our application uses **Riverpod** for state management, leveraging the **AsyncNotifier** pattern to handle asynchronous data and side effects with built-in loading and error states.

## Authentication State Machine

The `AuthController` manages the global authentication lifecycle using an `AsyncNotifier<AuthState>`.

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

### State Definitions
- **Initializing**: The app is checking local storage for valid JWTs.
- **Guest**: Anonymous mode with local usage tracking.
- **Authenticated**: User is logged in with access to history and profile management.
- **SessionExpired**: A specialized state where the user must re-authenticate or continue as guest after a refresh failure.

## Chat Query Flow

The following diagram illustrates the lifecycle of a single query, including guest rate limiting and error handling logic.

```mermaid
sequenceDiagram
    participant U as User
    participant C as ChatController (AsyncNotifier)
    participant R as ChatRepository
    participant B as Backend
    
    U->>C: sendMessage(text)
    C->>C: Push user message (Optimistic UI)
    C->>C: Transition to AsyncLoading
    
    alt Guest Mode
        C->>R: sendQuery(text, guest_id)
        R->>B: POST /api/chat/query
        alt Rate Limit (429)
            B-->>R: Error response
            R-->>C: throw RateLimitException
            C->>C: Transition to AsyncError
            C-->>U: Show RateLimit Modal
        else OK
            B-->>R: 200 OK (Answer + Remaining)
            R-->>C: AnswerResult
            C->>C: Update state with answer & count
        end
    else Authenticated
        C->>R: sendQuery(text, conv_id)
        R->>B: POST /api/chat/query (JWT)
        B-->>R: 200 OK (Answer)
        R-->>C: AnswerResult
        C->>C: Append answer to conversation history
    end
```

## Provider Dependency Graph

Riverpod enforces a clear dependency directional flow to ensure predictable state updates:

```mermaid
graph BT
    Router[AppRouter] --> AuthC[AuthController]
    AuthC --> AuthR[AuthRepository]
    ChatC[ChatController] --> ChatR[ChatRepository]
    ChatR --> Dio[DioProvider]
    AuthR --> Dio
    Dio --> Interceptor[HttpInterceptor]
    Interceptor --> AppLogger[AppLogger]
```

## Key Architectural Constraints
1. **Unidirectional Data Flow**: UI triggers actions in Controllers -> Controllers call Repositories -> Repositories call API -> State updates -> UI rebuilds.
2. **Immutable State**: Use `@freezed` for all state classes to prevent accidental side effects.
3. **Optimistic Updates**: Use optimistic UI patterns for chat messages to maintain a "snappy" feel despite network latency.
