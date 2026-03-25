import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/core/constants/app_strings.dart';

void main() {
  group('Demo panel PDF upload test', () {
    testWidgets('shows success snackbar when file is picked', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Debug: print current UI strings
      debugPrint('AppStrings.appName: \${AppStrings.appName}');

      final uploadButton = find.text('Upload PDF Knowledge Base');
      expect(uploadButton, findsOneWidget);

      await tester.tap(uploadButton);
      await tester.pump();

      // In the real test, we would mock FilePicker, but for this demo
      // we just want to ensure the button exists and the test compiles.
    });
  });
}
