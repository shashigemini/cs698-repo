# ADR 0001: Use Riverpod for State Management

## Status
Accepted

## Context
The application requires a robust state management solution that handles:
1.  Asynchronous data fetching (API calls).
2.  Global authentication state and session lifecycle.
3.  Platform-specific dependency injection (Storage, Controllers).
4.  Scalability across many features.

## Decision
We chose **Riverpod (v3)** over Provider or Bloc.

### Rationale
- **Compile-time Safety**: Riverpod catches provider-missing errors at compile-time, not runtime.
- **Async Interop**: Built-in support for `AsyncValue` simplifies loading/error states in the UI.
- **Provider Refactoring**: The generator (`riverpod_generator`) removes boilerplate and enforces best practices.
- **Testability**: Riverpod is designed for easy overriding of providers in unit and widget tests.

## Consequences
- Requires a code-generation step (`build_runner`).
- Developers must learn the `ref.watch` vs `ref.read` patterns.
- Ensures a declarative, unidirectional data flow across the app.
