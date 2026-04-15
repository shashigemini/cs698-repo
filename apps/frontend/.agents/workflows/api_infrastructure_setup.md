---
description: How to safely implement and test the Remote API Infrastructure Setup (Phase 1)
---

# Remote API Infrastructure Setup Workflow

This workflow explicitly incorporates lessons from `.agents/rules/ai-rules-project.md` and `.agents/rules/ai-rules-flutter.md` to guarantee a smooth, error-free implementation, particularly on Windows. It is designed to be easily readable and strictly executable by an AI assistant.

## Phase 1: Environment Variables (`flutter_dotenv`)

### 1. File Setup
- Create `.env` and `.env.example` in `frontend/`.
- Add `API_BASE_URL=http://localhost:8080/api/v1` to both.
- **CRITICAL**: Ensure `.env` is added to `.gitignore`.

### 2. Configuration Class
- Create `frontend/lib/core/config/env_config.dart`.
- Create a typed static class `EnvConfig` with getters for `baseUrl` and `isDevelopment`.
- Throw an explicit `AssertionError` if `dotenv.env` is missing required keys when `baseUrl` is accessed.

### 3. Application Initialization
- In `frontend/lib/main.dart` and `frontend/lib/main_dev.dart`:
  - Import `package:flutter_dotenv/flutter_dotenv.dart`.
  - Add `await dotenv.load(fileName: ".env");` *before* `runApp()`.

---

## Phase 2: HTTP Client Setup (`dio`)

### 1. Dio Provider
- Create `frontend/lib/core/network/dio_provider.dart`.
- Define a `@Riverpod(keepAlive: true)` provider that returns a `Dio` instance.
- **Configuration**:
  - `baseUrl: EnvConfig.baseUrl`
  - `connectTimeout: const Duration(seconds: 10)`
  - `receiveTimeout: const Duration(seconds: 10)`
- **Rule Reminder**: NEVER export bare `Provider` configurations. Always use `@riverpod` or `@Riverpod(keepAlive: true)` generator syntax in this project.

### 2. Logging Interceptor
- Create `frontend/lib/core/network/logging_interceptor.dart` extending `Interceptor`.
- **Rule Reminder**: "No `print()` — use `logger` package". Use `AppLogger.d()` to log outgoing requests (URL/Method) and incoming responses (Status Code/Body).

---

## Phase 3: Auth Interceptor

### 1. Interceptor Logic
- Create `frontend/lib/core/network/auth_interceptor.dart`.
- Requires the `Ref` (or specifically `StorageService`) to access stored tokens.
- **`onRequest`**:
  - Read `accessToken` from `StorageService`.
  - If it exists, add header: `options.headers['Authorization'] = 'Bearer $accessToken'`.
- **`onError`**:
  - If `err.response?.statusCode == 401`:
    1. Read `refreshToken`.
    2. Make an explicit Dio API call to the refresh endpoint (do not use the intercepted Dio instance, use a standalone one to avoid infinite loops).
    3. If refresh succeeds: Save new tokens, retry original request (`handler.resolve(await dio.fetch(err.requestOptions))`).
    4. If refresh fails: Clear `StorageService`, throw error (UI/Router handles logout).

### 2. Unit Testing the Interceptor
- Create `frontend/test/core/network/auth_interceptor_test.dart`.
- **Rule Reminder - Mocks**: Use `mocktail`. Register fallback values in `setUpAll()` for any custom types (like `RequestOptions`).
- **Rule Reminder - SecureStorage**: Secure storage uses platform channels and hangs in tests. You MUST use `MockStorageService` to simulate the persistent tokens in tests.
- **Test Cases Needed**:
  - Valid token is attached to `onRequest`.
  - No token is attached if storage is empty.
  - 401 Triggers a refresh attempt.

---

## Phase 4: Data Transfer Objects (DTOs)

### 1. DTO Generation
- Create files: `frontend/lib/features/auth/data/dto/auth_dtos.dart` and `frontend/lib/features/chat/data/dto/chat_dtos.dart`.
- **Rule Reminder**: Use `@freezed` and `json_serializable`.
- Examples: `LoginRequestDto`, `TokenResponseDto`, `QueryRequestDto`, `AnswerResponseDto`.

### 2. Running Code Generation (Windows Rules)
- **CRITICAL WINDOWS RULE**: NEVER use `flutter pub run build_runner`. NEVER use PowerShell wrappers. 
- **CRITICAL WINDOWS RULE**: If a previous run hung, kill all `dart.exe` processes and delete `.dart_tool/build` before re-running.
- **Command to Execute**:
  ```bash
  cd frontend
  dart run build_runner build --delete-conflicting-outputs
  ```

### 3. Unit Testing DTOs
- Create `frontend/test/features/auth/data/dto/auth_dtos_test.dart`.
- Verify `fromJson` and `toJson` correctly map between JSON maps and the DTO instances.

---

## Execution Checklist for AI Agent

When executing this workflow, follow these strict guidelines:
1. Do not modify `MockChatRepository` or `MockAuthRepository`. They stay exactly as they are.
2. If tests fail with "A Timer is still pending" or "No element found" (Windows), ensure you are not using `pumpAndSettle` with an infinite animation, and that you manually clear snackbars before UI finders.
3. Use the `write_to_file` and `run_command` tools sequentially. Do not batch everything into one massive `write_to_file` call. 
4. After writing all code, explicitly execute `flutter analyze` and `dart run build_runner build --delete-conflicting-outputs` before running tests.
