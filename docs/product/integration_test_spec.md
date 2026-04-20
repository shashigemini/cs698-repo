# Integration Test Specification (P6)

## 1. Architectural Scope & Dependencies
Validate end-to-end functionality across the full stack. The testing infrastructure relies on a containerized backend and Flutter SDK testing tools.

*   **Backend Dependencies**: `apps/backend/docker-compose.e2e.yml` provisions the isolated E2E stack (FastAPI, PostgreSQL 15, Qdrant, Redis).
*   **Frontend Dependencies**: Flutter SDK (`flutter test`), `integration_test` package.
*   **Linux/CI Dependencies**: `xvfb` (X Virtual Framebuffer), `libgtk-3-dev` to enable headless GUI rendering for Flutter integration tests.

## 2. Execution Pipeline
The automated E2E pipeline is driven by shell scripts and Dart runners, explicitly defined to avoid OS-level resource locks.

1.  **Bootstrap**: `apps/frontend/tool/run_e2e.sh` launches the Docker compose stack in detached mode (`--force-recreate`).
2.  **Health & Data Seeding**: Polling `http://localhost:8000/health/full` for readiness. Upon success, invokes `POST /api/test/seed` to inject deterministic user and vector data into PostgreSQL and Qdrant.
3.  **Environment Prep**: Generates `.env` for the Flutter app and runs `dart run build_runner build` to compile code generation (Riverpod/Freezed).
4.  **Sequential Runner**: Invokes `apps/frontend/tool/run_integration_tests.dart`. This Dart script detects the OS. On Linux/CI, it wraps `flutter test -d linux --reporter json` inside `xvfb-run` and executes each test file sequentially, capturing JSON stdout to generate clean terminal logs at `apps/frontend/test_results/`.

## 3. GitHub Actions CI/CD Configuration
Defined in `.github/workflows/run-integration-tests.yml`.
*   **`local-fullstack-integration` (PR Gate)**: Triggers on PRs modifying `apps/`. Installs `xvfb`, enables Flutter Linux desktop, and executes `bash apps/frontend/tool/run_e2e.sh`. Validates local containerized logic.
*   **`cloud-target-validation` (Manual)**: Triggers via `workflow_dispatch`. Skips Docker setup. Receives a live AWS API URL (`target_url`), writes it to the `.env`, and executes `run_integration_tests.dart` directly against the deployed Amplify/EC2 environment.

## 4. Test Specifications & Table

The integration tests leverage the **Robot Pattern** (located in `apps/frontend/integration_test/robot/`) to decouple UI interaction logic from test assertions.

| Test ID | File & Robot Dependencies | Purpose & Endpoints Triggered | Test Inputs / Actions | Expected Output & Assertions |
| :--- | :--- | :--- | :--- | :--- |
| **E2E-01** | `e2e_auth_test.dart`<br>*Robots: Auth, Home* | **User Registration**<br>`POST /api/auth/register` | Open Register; Input `newuser@e2e.com` / `SecurePass123!`; Submit. | Mnemonic generation dialog appears. Confirming lands user on the Home Screen (Drawer becomes visible). |
| **E2E-02** | `e2e_auth_test.dart`<br>*Robots: Auth, Home* | **User Login (Seeded)**<br>`POST /api/auth/login` | E2E Utils seeds user via API. Input `seeded@e2e.com` / `SeededPass123!`; Submit. | Cryptographic keys are derived successfully; user navigates to the Home Screen. |
| **E2E-03** | `e2e_auth_test.dart`<br>*Robots: Auth* | **Auth Error Handling**<br>`POST /api/auth/login` | Input `seeded@e2e.com` / `WrongPassword123!`; Submit. | UI displays "Invalid email or password" snackbar; user remains locked on the Login screen. |
| **E2E-04** | `e2e_chat_test.dart`<br>*Robots: Auth, Home* | **Guest Chat & RAG**<br>`POST /api/chat/query` | Select Guest Login. Submit query: "What is the true nature of reality?" | Qdrant retrieval succeeds; UI renders specific canned response text and "Inner Peace E2E test" citation cards. |
| **E2E-05** | `e2e_chat_test.dart`<br>*Robots: Auth, Home* | **Guest Rate Limiting**<br>`POST /api/chat/query` | Within a Guest session, submit 4 sequential queries. | HTTP 429 logic succeeds; the 4th query is blocked and a rate limit banner is rendered in the UI. |
| **E2E-06** | `e2e_chat_test.dart`<br>*Robots: Auth, Home* | **Chat Persistence**<br>`GET /api/chat/conversations` | Login as Authenticated. Send query. Receive response. Open Drawer. | Conversation history (persisted in Postgres) is successfully loaded via API and rendered in the Sidebar list. |
| **E2E-07** | `e2e_settings_test.dart`<br>*Robots: Auth, Home, Settings* | **Password Rotation**<br>`PUT /api/auth/password` | Navigate to Settings. Input Old and New password. Submit. Logout. | Backend re-encrypts account key. Subsequent login succeeds *only* with the new password. |
| **E2E-08** | `e2e_chat_test.dart`<br>*Robots: Home, Settings* | **Delete Conversation**<br>`DELETE /api/chat/conversations/{id}` | Open Settings. Tap per-conversation "Delete" icon on the seeded conversation. | API success; Snackbar confirmation appears, and conversation is removed from both the UI list and the database. |
| **E2E-09** | `e2e_settings_test.dart`<br>*Robots: Auth, Home, Settings* | **Account Deletion**<br>`DELETE /api/auth/account` | Navigate to Settings. Tap "Delete Account" and confirm via modal. | Immediate redirection to Auth screen. Subsequent login attempts return 401 Unauthorized. |
| **E2E-10** | `e2e_full_workflow_test.dart`<br>*Robots: All* | **Full State Machine**<br>*All Endpoints* | Register -> Chat -> Change Password -> Logout -> Login -> Verify Chat -> Delete Account. | Chains modules sequentially. Asserts global state consistency across module boundaries without failure. |
