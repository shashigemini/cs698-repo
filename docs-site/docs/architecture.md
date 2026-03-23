---
title: "System Architecture"
sidebar_position: 2
---

# End-to-End Architecture

This document provides a high-level overview of the Spiritual Q&A Platform's architecture, including its components, data flow, and technology stack.

## High-Level System Diagram

```mermaid
flowchart LR
    subgraph Client["Client (Flutter Web/iOS/Android)"]
        S["Startup Logic"]
        AUIS["Auth Screens<br/>(Guest/Login/Register)"]
        CH["Chat Screen<br/>(Guest & Auth)"]
        LS["StorageService<br/>(tokens & guest_session_id)"]
    end

    subgraph Backend["Backend (FastAPI, Python)"]
        subgraph AuthLayer["Auth & Security"]
            AUTH_EPS["/Auth endpoints<br/>/api/auth/*"]
            AU["AuthService<br/>(JWT/OAuth2 + password hashing + deletion)"]
        end

        subgraph ChatLayer["Chat & RAG"]
            CHAT_EP["/POST /api/chat/query/"]
            RL["RateLimiter<br/>(IP + guest_session_id)"]
            RAG["RAGService<br/>(LlamaIndex + OpenAI gpt-4.1-mini)"]
        end
    end

    subgraph Data["Data & Storage"]
        P[("PostgreSQL<br/>users, sessions, messages, documents")]
        Q[("Qdrant Vector DB")]
        FS["/Local PDF Storage/"]
    end

    subgraph LLM["LLM Provider"]
        O["OpenAI gpt-4.1-mini API"]
    end

    S --> LS
    S --> AUIS
    AUIS --> AUTH_EPS
    AUIS --> CH
    CH --> CHAT_EP

    AUTH_EPS --> AU
    AU --> P
    P --> AU

    CHAT_EP --> RL
    CHAT_EP --> AU
    CHAT_EP --> RAG

    RAG --> Q
    Q --> RAG
    RAG --> FS
    RAG --> O
    O --> RAG

    CHAT_EP --> P
    CHAT_EP --> CH
```

## Component Deployment

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Flutter Client** | Dart / Flutter | Cross-platform UI (Web, iOS, Android) |
| **FastAPI Backend** | Python / FastAPI | REST API, Auth, and RAG orchestration |
| **PostgreSQL** | Relational DB | User data, session persistence, document metadata |
| **Qdrant** | Vector DB | Semantic search and document chunk storage |
| **LlamaIndex** | RAG Framework | Orchestrating retrieval and LLM response |
| **OpenAI API** | gpt-4.1-mini | Natural language generation |

## Frontend Layered Architecture

The application follows a feature-based, layered architecture designed for testability and maintainability.

### 1. Presentation Layer (`lib/features/*/presentation`)
- **Widgets**: Reusable UI components.
- **Screens**: Orchestrate multiple widgets and watch application state via Riverpod.

### 2. Application Layer (`lib/features/*/application`)
- **Controllers**: (Riverpod `AsyncNotifier`) Orchestrate business logic and maintain UI state.

### 3. Domain Layer (`lib/features/*/domain`)
- **Models**: Immutable data structures (Freezed).
- **Interfaces**: Abstract definitions for repositories.

### 4. Data Layer (`lib/features/*/data`)
- **Repositories**: Implementation of domain interfaces making network calls.
- **Services**: Platform-specific abstractions (Storage, Security).

## Entry Points

- **Production (`lib/main.dart`)**: Initializes core services and starts the app.
- **Development (`lib/main_dev.dart`)**: Includes mock overrides and **Marionette** integration for automated testing.
