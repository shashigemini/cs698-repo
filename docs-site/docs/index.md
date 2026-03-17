# Introduction

Welcome to the **Spiritual Q&A Platform Documentation Hub**. This site serves as the "source of truth" for the application's architecture, development practices, and API specifications.

## Quick Start

If you are a new developer joining the project, start here:

1.  **[Architecture](./architecture)**: Understand the layered structure and core components.
2.  **[State Management](./state-management)**: Learn how we handle global and ephemeral state with Riverpod.
3.  **[Testing](./testing)**: Review the Robot Pattern and stability rules for Windows/CI.
4.  **[Security](./security)**: Understand JWT authentication, transport security, and data privacy.
5.  **[API Reference](file:///workspaces/cs698-repo/docs/openapi.yaml)**: Browse the raw OpenAPI specification.

## Core Principles

- **Immutability First**: Domain models and application states are strictly immutable.
- **Tests as Documentation**: Integration tests (Robots) describe intended behavior and user flows.
- **Premium Aesthetics**: UI must feel polished, responsive, and follow the organization's design guidelines.
- **Zero-Log Diagnostics**: All diagnostic logs are scrubbed of sensitive PII.

## Project Metadata

- **Organization**: Spiritual Guidance Organization
- **Platforms**: iOS, Android, Web
- **Backend**: Python (FastAPI)
- **Frontend**: Flutter (Riverpod)
- **RAG Engine**: LlamaIndex + Qdrant
