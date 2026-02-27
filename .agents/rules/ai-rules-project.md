---
trigger: always_on
---

# AI Rules: Project-Specific Lessons Learned
Proven solutions to recurring issues. Follow to avoid re-discovering fixes.
---

## 1. Project Architecture

```
frontend/
├── lib/
│   ├── main.dart              # Entry (ProviderScope + GoRouter)
│   ├── main_dev.dart          # Dev entry with mock overrides
│   ├── core/
│   │   ├── constants/         # AppStrings (business-specific text)
│   │   ├── router/            # app_router.dart (GoRouter config)
│   │   └── utils/             # validators.dart
│   ├── features/
│   │   ├── auth/              # Login/Register, MockAuthRepository
│   │   ├── chat/              # ChatController, MockChatRepository
│   │   ├── home/              # HomeScreen + private widgets
│   │   └── startup/           # StartupScreen (splash)
│   ├── gen/                   # Generated assets (flutter_gen)
│   └── theme/                 # AppTheme, gradients, glassmorphism
├── test/                      # Unit + Widget tests
├── integration_test/          # E2E (Robot Pattern: AuthRobot, HomeRobot)
└── pubspec.yaml
```

### Key Technology Decisions (Do NOT change without approval)
- **State**: `flutter_riverpod` v3 + `riverpod_generator` v4
- **Code Gen**: `freezed`, `riverpod_generator`, `json_serializable`
- **Routing**: `go_router` v17
- **HTTP**: `dio` + custom `HttpInterceptor`
- **Testing**: `mocktail`, `integration_test` SDK
- **Styling**: Glassmorphism, Purple-Blue-Teal gradients, Google Fonts

---

## 2. Build Tooling (Windows)

### `build_runner`

```bash
# The ONLY correct way:
dart run build_runner build --delete-conflicting-outputs
```

**DO NOT** use `flutter pub run build_runner` (deprecated), PowerShell wrappers (hangs), or `cmd /c` wrappers (hangs). Kill if running >5 min.

**Code-gen needed after**: modifying `@freezed`, `@riverpod`, `@JsonSerializable` classes, or `pubspec.yaml` assets.
**NOT needed for**: widget `build()` changes, string/color/layout edits, test files, routing config.

**If hung**: Kill all `dart`/`build_runner` processes → delete `.dart_tool/build` → `dart pub get` → retry.

---

## 3. Flutter Testing Rules

### 3.1 `pumpAndSettle` — #1 Test Killer

Never use `pumpAndSettle()` with infinite animations (`_TypingIndicator`, `CircularProgressIndicator`, `LinearProgressIndicator`, `RepeatEffect`).

```dart
// GOOD alternatives:
await tester.pump(const Duration(milliseconds: 500));
await tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 5),
);
```

### 3.2 Fake Async Zone

In widget tests, do NOT call methods using `Future.delayed` or real timers — use synchronous setup:
```dart
// BAD: await mockAuthRepo.login('test@test.com', 'password');
// GOOD: mockAuthRepo.setUser(MockUser(email: 'test@test.com'));
```

For streams, avoid `emitsInOrder` (blocks). Use `emits(finalState)`.

### 3.3 Widget Test Setup

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepo),
      chatRepositoryProvider.overrideWithValue(mockChatRepo),
    ],
    child: MaterialApp(home: const ScreenUnderTest()),
  ),
);
```

### 3.4 Test Commands

```bash
flutter test                                                    # Widget tests
flutter test test/path/to/file_test.dart                        # Single file
flutter test integration_test/app_test.dart -d windows          # Integration
flutter test integration_test/app_test.dart -d windows --reporter expanded
```

Integration tests **require** `-d windows` (or `-d <device_id>`). Parallel execution on Windows may cause resource locks (files/ports); prefer sequential runs for final verification.

### 3.5 Robot Pattern

Use `AuthRobot`/`HomeRobot` from `integration_test/robot/` instead of raw finders:
```dart
final authRobot = AuthRobot(tester);
await authRobot.enterEmail('test@example.com'); // Robot should tap field first for focus stability
await authRobot.tapLogin();
```

### 3.6 MCP Testing

- **Marionette**: AI-driven exploratory testing (not CI/CD)
- **`integration_test`**: Primary tool for deterministic E2E tests.
    - **Snackbar Races**: Always call `ScaffoldMessenger.of(context).clearSnackBars()` before `showSnackBar()`. In tests, snackbars queue, which can cause `find.text()` to find the *previous* snackbar if not cleared.
    - **List Stability**: Use `ValueKey(item.id)` for items in `ListView.builder`. Without unique keys, the `WidgetTester` may fail to locate items correctly after deletions or search resets due to widget recycling.
    - **Duplicate Key Collisions**: Avoid hardcoded keys like `Key('item_label')` inside repeating widgets. Even if the parent has a unique `ValueKey`, inner hardcoded keys will collide when multiple items exist, leading to state corruption and finder failures.
    - **Robust Action Finders**: Use `find.descendant` with `of: find.byType(ListTile)` to target specific buttons (Export/Delete) belonging to a specific item.

---

## 4. Deprecated API Mapping

| Deprecated | Replacement | Since |
|---|---|---|
| `color.withOpacity(0.5)` | `color.withValues(alpha: 0.5)` | Flutter 3.27 |
| `flutter pub run <pkg>` | `dart run <pkg>` | Flutter 3.22 |
| `GoRouterRef` / `*Ref` (generated) | `Ref` (riverpod) | riverpod_generator 4.x |
| Removed lint rules (`always_require_non_null_named_parameters`, etc.) | Remove from analysis_options | Dart 3.x |

---

## 5. Windows Environment Checklist

- **Developer Mode** enabled (Settings → Privacy → For Developers)
- **C++ ATL build tools** installed (VS Installer → Desktop C++ → ATL v143)
- **Restart terminal** after enabling Developer Mode
- **No zombie `dart.exe`**: Check Task Manager before `build_runner`. If `test_results.json` is locked, kill all `dart` processes.
- **Log Encoding**: `flutter test --reporter json` on Windows outputs **UTF-16LE**. Ensure log extraction scripts (Python/PowerShell) handle this encoding explicitly, or convert to **UTF-8** using `Out-File -Encoding utf8`.

---

## 6. Code Style

### Private Widget Classes, NOT Helper Methods
```dart
// BAD: Widget _buildBubble(Message m) => Container(...);
// GOOD:
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final Message message;
  @override
  Widget build(BuildContext context) => Container(...);
}
```

### Immutability
- Domain models: `@immutable` + `const` constructors or `@freezed`
- Freezed: `ChatState`, `AuthState`
- Immutable: `Message`, `Citation`, `AnswerResult`, `TokenPair`

### State Management
- `ref.watch()` in `build()` only. `ref.read()` in callbacks. Never `ref.watch()` outside `build()`.

### No `print()` — use `logger` package

### Business-Specific Strings
All domain text lives in `lib/core/constants/app_strings.dart`. Do NOT hardcode brand names, suggestions, or domain terms in widgets.

---

## 7. Common Gotchas

- **GoRouter in Tests**: Wrap with `MaterialApp.router(routerConfig: router)` not `MaterialApp(home: Screen())`
- **Freezed stale**: Delete `.freezed.dart` → rerun `build_runner`
- **Mock repos**: Interface in `domain/`, mock in `data/`, provider in `data/` (overridable)
- **Chat input**: 2,000 char limit with visible counter
- **Guest mode**: 3 queries (configurable in `AppStrings`) → rate limit modal → "Sign In" / "Maybe Later"
- **ScaffoldMessenger Context**: `ScaffoldMessenger.of(context)` needs a context *below* the `ScaffoldMessenger`. In integration tests, use `tester.element(find.byType(Scaffold).first)` instead of the root app widget type.
- **Duplicate Keys in Lists**: A parent `ValueKey` does NOT prevent inner child keys (like a `Container(key: Key('shared'))`) from colliding across siblings.

---

## 8. Integration Test Diagnosis (Windows)

If integration tests fail with "No element found" but the screen looks correct:

1.  **Black-Box Visibility**: Add `debugPrint('Step: ...')` to the test and robots. Add `debugPrint('Component: ...')` to the app callbacks.
2.  **Full Log Capture**: 
    ```bash
    flutter test integration_test/your_test.dart -d windows --reporter json > test_results.json 2>&1
    ```
3.  **Encoding Fix**: Convert `test_results.json` to UTF-8 before parsing if using standard Python `json.loads` without `utf-16le` support.
4.  **Wait Strategy**: If `pumpAndSettle()` times out, use `await tester.pump(Duration(seconds: 1))` to wait for mock repo delays or snackbars to transition.
5.  **Build Method Debugging**: If a list refuses to render correctly after a search/filter update, add `debugPrint` inside the `build()` method to inspect the filtered collection length and current state variables.
