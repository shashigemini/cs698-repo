import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'robot/auth_robot.dart';
import 'robot/home_robot.dart';
import 'robot/settings_robot.dart';
import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    debugPrint('Wiping storage for test isolation...');
    await wipeStorage();
  });

  testWidgets(
    'Authenticated Settings Flow - History Search and Account Deletion',
    (tester) async {
      debugPrint('[Start] Authenticated Settings Flow');
      await buildTestApp(tester);

      final authRobot = AuthRobot(tester);
      final homeRobot = HomeRobot(tester);
      final settingsRobot = SettingsRobot(tester);

      debugPrint('Step: Waiting for initial app startup...');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      debugPrint('Step: Logging in with test@example.com...');
      await authRobot.enterEmail('test@example.com');
      await authRobot.enterPassword('password');
      await authRobot.tapLogin();

      debugPrint('Step: Waiting for login and navigation to Home...');
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      debugPrint('Step: Opening Drawer...');
      await homeRobot.openDrawer();

      debugPrint('Step: Tapping Settings item...');
      await homeRobot.tapSettings();

      debugPrint('Step: Verifying Settings Screen headers...');
      await tester.pumpAndSettle();
      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Conversation History'), findsOneWidget);

      debugPrint('Step: Testing history search for "Ancient"...');
      await settingsRobot.enterSearch('Ancient');

      debugPrint('Step: Verifying search results match "Ancient wisdom"...');
      expect(find.text('Ancient wisdom'), findsOneWidget);
      expect(find.text('Modern Science'), findsNothing);

      debugPrint('Step: Testing export for "Ancient wisdom"...');
      await settingsRobot.tapExport('Ancient wisdom');

      debugPrint('Step: Verifying export snackbar...');
      // Export has a 500ms mock delay — pump past it before checking
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Conversation exported'), findsOneWidget);

      debugPrint('Step: Testing deletion for "Ancient wisdom"...');
      await settingsRobot.tapDeleteConversation('Ancient wisdom');

      debugPrint('Step: Verifying deletion snackbar...');
      // Delete (300ms) + re-fetch (500ms) mock delays
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Conversation deleted'), findsOneWidget);

      debugPrint('Step: Verifying empty search state message...');
      await tester.pumpAndSettle();
      expect(find.text('No matching conversations found.'), findsOneWidget);

      debugPrint('Step: Clearing search to see all remaining conversations...');
      // Clear snackbars to avoid potential race conditions on Windows
      if (find.byType(Scaffold).evaluate().isNotEmpty) {
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).first),
        ).clearSnackBars();
      }
      await settingsRobot.enterSearch('');

      debugPrint('Step: Verifying conversation items are visible again...');
      expect(settingsRobot.conversationItems, findsWidgets);

      debugPrint('Step: Navigating to Delete Account button (Danger Zone)...');
      await settingsRobot.tapDeleteAccount();

      debugPrint('Step: Verifying Deletion Confirmation Dialog...');
      expect(find.text('Delete Account?'), findsOneWidget);

      debugPrint('Step: Confirming account deletion...');
      await settingsRobot.confirmDeleteAccount();

      debugPrint('Step: Waiting for logout redirect to Login screen...');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      debugPrint('Step: Verifying Login button is visible...');
      expect(authRobot.loginButton, findsOneWidget);

      debugPrint('[End] Authenticated Settings Flow - SUCCESS');
    },
  );
}
