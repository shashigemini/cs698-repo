---
description: How to run Flutter integration tests on Windows with proper logging, live trace support, and UTF-8 encoding.
---

# Running Integration Tests on Windows (Standardized Methodology)

This workflow solidifies the industry-standard and project-specific approach to running integration tests, capturing device logs, and diagnosing errors natively on Windows. **It explicitly avoids brittle Python scripts or PowerShell redirections by relying on a native Dart script.**

## 1. Execution (Dart CLI)

Running integration tests on Windows requires sequential execution to prevent resource locks on the debug port or `.dart_tool` cache, and explicit in-memory parsing to bypass UTF-16LE Windows log mangling.

// turbo
1. Run the dedicated Dart tool to execute all tests securely and parse their JSON outputs:
```bash
dart run tool/run_integration_tests.dart
```

This single command loops through `integration_test/`, executes them sequentially, bypasses Windows command encoding issues, and prints beautifully formatted failure tracebacks.

## 2. Diagnostics & Live Tracing (MCP + Native Tools)

When an integration test fails natively (`No element found`), and you need a "live trace" of the widget tree or device state:

1. **Native Flutter Diagnostics**:
   In the failing test, temporarily wrap the action with a debug dump:
   ```dart
   debugDumpApp(); // Dumps entire widget tree to console
   debugDumpRenderTree(); // Dumps render layout constraints
   ```
   Or capture a UI snapshot immediately before the failure:
   ```dart
   final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
   await binding.takeScreenshot('failure_trace_1');
   ```

2. **Using dart-mcp-server**:
   Instead of struggling with raw CLI logs, you can utilize the `mcp_dart-mcp-server_run_tests` tool internally when working on this repository, which handles the `package:test` runner seamlessly.
   Alternatively, launch the app in debug mode with `mcp_dart-mcp-server_launch_app`, connect to the DTD URI, and invoke `mcp_dart-mcp-server_get_app_logs` and `mcp_dart-mcp-server_get_runtime_errors` for live traces.

3. **Using marionette MCP**:
   For UI-heavy debugging beyond tests, start the app with `flutter run -d windows` natively, locate the `ws://...` VM service URI, and call `mcp_marionette_connect`. You can then:
   - Call `mcp_marionette_get_interactive_elements` to live-trace the widget tree.
   - Call `mcp_marionette_take_screenshots` to capture the visual trace.
   - Call `mcp_marionette_get_logs` for deep framework tracing.
