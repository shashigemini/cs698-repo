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

  // Password Rotation
  Finder get changePasswordButton => find.text('Change Password');
  Finder get oldPasswordField => find.byKey(const Key('old_password_field'));
  Finder get newPasswordField => find.byKey(const Key('new_password_field'));
  Finder get changePasswordSubmitButton =>
      find.byKey(const Key('change_password_submit_button'));

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

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button, warnIfMissed: true);
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteConversation(String conversationTitle) async {
    debugPrint('Robot: Tapping delete button for "$conversationTitle"');
    final button = deleteButtonForItem(conversationTitle);

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button, warnIfMissed: true);
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
    await tester.ensureVisible(deleteAccountButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteAccountButton, warnIfMissed: true);
    await tester.pumpAndSettle();
  }

  Future<void> confirmDeleteAccount() async {
    debugPrint('Robot: Tapping Confirm Delete button in dialog');
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    debugPrint('Robot: Starting password change flow in SettingsScreen');

    // Ensure the button is visible - it might be at the bottom
    await tester.dragUntilVisible(
      changePasswordButton,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    debugPrint('Robot: Tapping Change Password button');
    await tester.ensureVisible(changePasswordButton);
    await tester.tap(changePasswordButton);
    await tester.pumpAndSettle();

    debugPrint('Robot: Entering passwords in dialog');
    await tester.enterText(oldPasswordField, oldPassword);
    await tester.pumpAndSettle();
    await tester.enterText(newPasswordField, newPassword);
    await tester.pumpAndSettle();

    debugPrint('Robot: Tapping Update Password button');
    await tester.tap(changePasswordSubmitButton);
    // Dialog closure might trigger animations, so use manual pump
    await tester.pump(const Duration(milliseconds: 1500));
  }
}
