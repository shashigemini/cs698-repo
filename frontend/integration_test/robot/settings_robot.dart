import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SettingsRobot {
  final WidgetTester tester;

  SettingsRobot(this.tester);

  // Finders
  Finder get searchField => find.byType(TextField);
  Finder get deleteAccountButton => find.text('Delete Account Permanently');
  Finder get confirmDeleteButton => find.text('Delete').last;
  Finder get conversationItems => find.byType(ListTile);

  // Robust finders for specific items
  Finder exportButtonForItem(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
    matching: find.byTooltip('Export'),
  );

  Finder deleteButtonForItem(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
    matching: find.byTooltip('Delete'),
  );

  // Actions
  Future<void> enterSearch(String query) async {
    debugPrint('Robot: Entering search query: "$query"');
    await tester.tap(searchField);
    await tester.pumpAndSettle();
    await tester.enterText(searchField, query);
    await tester.pumpAndSettle();
  }

  Future<void> tapExport(String conversationTitle) async {
    debugPrint('Robot: Tapping export button for "$conversationTitle"');
    final button = exportButtonForItem(conversationTitle);

    // Ensure it's hittable
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button, warnIfMissed: true);

    debugPrint('Robot: Waiting for async export operation to finish...');
    // Mock has 500ms delay. We wait longer.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteConversation(String conversationTitle) async {
    debugPrint('Robot: Tapping delete button for "$conversationTitle"');
    final button = deleteButtonForItem(conversationTitle);

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button, warnIfMissed: true);

    debugPrint('Robot: Waiting for async delete operation to finish...');
    // Mock has 300ms delay.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteAccount() async {
    debugPrint('Robot: Tapping Delete Account button');
    await tester.dragUntilVisible(
      deleteAccountButton,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    // Ensure it's centered enough
    await tester.ensureVisible(deleteAccountButton);
    await tester.pumpAndSettle();

    await tester.tap(deleteAccountButton, warnIfMissed: true);
    // Give dialog time to animate in
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> confirmDeleteAccount() async {
    debugPrint('Robot: Tapping Confirm Delete button in dialog');
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();
  }
}
