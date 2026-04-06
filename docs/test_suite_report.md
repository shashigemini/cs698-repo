# Comprehensive Test Suite & Operations Report

This document serves as the **Single Source of Truth** for all testing activities within the `cs698-repo`. It is designed for both seasoned contributors and newcomers to the codebase.

---

## 1. Quick Start for Newcomers

If you just joined the project, follow these steps to verify your local environment:

### Step 1: Backend Baseline
Run the fast local test suite (SQLite-based, no Docker required):
```bash
./backend/scripts/run_local_tests.sh
```

### Step 2: Frontend Baseline
Run all unit and widget tests:
```bash
cd frontend
flutter test
```

### Step 3: Verified E2E Environment
Spin up the full Docker environment including Postgres, Redis, and Qdrant:
```bash
docker compose -f backend/dev_test/docker-compose.dev.yml up -d --build
```

---

## 2. Backend Testing Detail

The backend tests are located in `backend/tests/`. We categorize them into **Unit** and **Integration** tests based on their dependencies.

### A. Unit Tests (Logic Isolation)
These tests target specific functions and schemas without requiring external services (DB, Redis, AI).
*   **Location**: Files like `test_security.py` and `test_schemas.py`.
*   **Running a specific unit test file**:
    ```bash
    poetry run pytest backend/tests/test_security.py
    ```

### B. Integration Tests (API & Services)
These tests verify that our code interacts correctly with the Database and Redis.
*   **Local Integration (Fast)**: Uses `aiosqlite` (in-memory) and `MockRedis`.
    ```bash
    ./backend/scripts/run_local_tests.sh
    ```
*   **Dockerized Integration (Robust)**: Uses real Postgres and Redis containers to match production behavior.
    ```bash
    ./backend/scripts/run_tests.sh
    ```

### C. Key Backend Modules
| File | Categories | Focus |
| :--- | :--- | :--- |
| `test_api.py` | Integration | End-to-end HTTP request/response through FastAPI. |
| `test_auth_service.py` | Integration | Salt retrieval, password verification flows. |
| `test_security.py` | Unit | JWT creation, hashing logic (Argon2id). |
| `test_rag_logic.py` | Unit | Formatting context for AI queries and history management. |
| `test_rate_limiter.py` | Integration | Brute-force protection for login and registration. |

---

## 3. Frontend Testing Detail

Frontend testing is organized into **Unit/Widget** tests and **UI Integration** tests.

### A. Unit & Widget Tests (`frontend/test/`)
*   **Focus**: State management (Riverpod), UI rendering, and business logic.
*   **Command**:
    ```bash
    flutter test
    ```
*   **Common Files**: `test/features/auth/presentation/auth_robot.dart` (Robot pattern for auth tests).

### B. UI Integration Tests (`frontend/integration_test/`)
These verify the app across multiple screens. In our Linux dev container, these run in **headless mode** via `xvfb`.
*   **Command**:
    ```bash
    flutter test integration_test/app_test.dart
    ```

---

## 4. Cross-Module (E2E) Orchestration

E2E tests ensure that the **Flutter Frontend** correctly communicates with a **Live Backend Environment**.

### The Orchestration Flow:
1.  **Environment Setup**: A dedicated Docker Compose file (`docker-compose.e2e.yml`) spins up the backend and all 3 databases.
2.  **Data Seeding**: The test runner calls the `POST /api/test/seed` endpoint to populate known test users and vectors.
3.  **App Launch**: The Flutter test runner launches the GUI (or headless) and performs real HTTP requests to the backend.
4.  **Verification**: Status codes and UI states are asserted together.

**How to Run E2E**:
```bash
# From the root directory:
bash tool/run_e2e_integration.sh
```

---

## 5. Mutation Testing (Robustness)

We use `mutmut` to ensure our backend tests are not just covering lines, but are actually catching logic errors.

*   **Execution**:
    ```bash
    ./backend/scripts/run_mutation_tests.sh
    ```
*   **Reports**: Current status can be found in `backend/mutation_report.md`.
*   **Goal**: Reach a 100% kill rate for `app.core.security` and `app.rag.pdf_parser`. If a mutant "survives," it means a developer must add a stricter assertion to the corresponding test.

---

## 6. Project Testing Rules (Mandatory)

1.  **No `pumpAndSettle` with Infinite Animations**: If a widget contains a non-stopping loading indicator, use `await tester.pump(Duration(milliseconds: 500))` instead.
2.  **Mocktail Fallbacks**: Always register custom classes in `setUpAll()`.
3.  **Secure Storage**: Always use `MockStorageService` in tests to avoid "Missing Plugin" errors on Linux/Windows.
4.  **Logging Verification**: Use `caplog` (Python) to verify that sensitive data is **never** logged to the console.

---

> [!TIP]
> For any errors where a test "hangs" on Windows, check the Task Manager and kill any orphaned `dart.exe` or `python.exe` processes before retrying.
