import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('Settings screen smoke test', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    expect(find.text('Account Settings'), findsOneWidget);
  });
}
