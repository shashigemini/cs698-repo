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

  testWidgets('E2EE Password Rotation and Account Recovery Lifecycle', (
    tester,
  ) async {
    debugPrint('[Start] E2EE Lifecycle Test');
    await buildTestApp(tester);

    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);
    final settingsRobot = SettingsRobot(tester);

    const email = 'rotation_e2e@test.com';
    const oldPassword = 'OldPassword123!';
    const newPassword = 'NewPassword123!';
    const recoveryPassword = 'RecoveryPassword123!';

    // --- 1. Registration & Mnemonic ---
    debugPrint('Step 1: Starting User Registration...');
    await authRobot.switchToRegister();
    debugPrint('Test: Entered Registration tab');
    await authRobot.enterRegisterEmail(email);
    await authRobot.enterRegisterPassword(oldPassword);
    await authRobot.tapRegister();

    // Wait for mnemonic dialog (Argon2id derivation is slow, taking ~7-8s)
    debugPrint('Waiting for mnemonic dialog (Argon2id derivation is slow)...');
    var dialogFound = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find
          .byKey(const Key('mnemonic_confirm_button'))
          .evaluate()
          .isNotEmpty) {
        dialogFound = true;
        debugPrint('Mnemonic dialog found after ${i * 0.5}s!');
        break;
      }
    }

    if (!dialogFound) {
      debugPrint(
        'FAILURE: Mnemonic dialog button NOT FOUND. Dumping app tree...',
      );
      debugDumpApp();
    }
    expect(dialogFound, isTrue);

    // Extract mnemonic from the UI (it's inside the dialog)
    // In a real test, we might mock the clipboard or just check visibility.
    // For this robot, we'll just confirm we saw it and close.
    // However, if we want to test RECOVERY, we need that mnemonic.
    // Since we are using MockAuthRepository, we can predict it if we use a fixed seed,
    // or we can try to find the words in the UI.

    final mnemonicFinder = find.byType(Wrap); // The mnemonic is in a Wrap
    final wordWidgets = tester.widgetList<Text>(
      find.descendant(of: mnemonicFinder, matching: find.byType(Text)),
    );
    // Mnemonic is 16 words. Some widgets are index numbers "1.", "2.".
    // Filter out the numbers to get the mnemonic.
    final mnemonicWords = wordWidgets
        .map((w) => w.data!)
        .where((text) => !text.contains('.') && text.isNotEmpty)
        .toList();

    final mnemonic = mnemonicWords.join(' ');
    debugPrint('Test: SUCCESS - Extracted mnemonic: $mnemonic');
    expect(mnemonicWords.length, 16);

    debugPrint('Test: Confirming mnemonic dialog...');
    await authRobot.confirmMnemonic();
    debugPrint('Test: Mnemonic confirmed, waiting for Home redirect...');
    await tester.pumpAndSettle();

    // Should be at home screen now
    expect(homeRobot.chatInputField, findsOneWidget);

    // --- 2. Password Rotation ---
    debugPrint('Step 2: Rotating password...');
    await homeRobot.openDrawer();
    await homeRobot.tapSettings();
    await tester.pumpAndSettle();

    await settingsRobot.changePassword(oldPassword, newPassword);

    // Verify success snackbar (using text because robot doesn't have a specific check)
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Password changed successfully'), findsOneWidget);

    // Close snackbar
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    // Logout
    await tester.pageBack(); // Go back from settings
    await tester.pumpAndSettle();
    await homeRobot.openDrawer();
    await homeRobot.tapLogout();
    await tester.pumpAndSettle();

    // --- 3. Login Verification ---
    debugPrint('Step 3: Verifying logins...');
    // Old password should fail
    debugPrint('Test: Attempting login with OLD password (should fail)');
    await authRobot.login(email, oldPassword);
    debugPrint('Test: Waiting for login failure snackbar...');
    // Failed login doesn't redirect, so pumpAndSettle in tapLogin should have handled it,
    // but we add a bit more for the snackbar text visibility.
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('Invalid credentials'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    // New password should succeed
    debugPrint('Test: Attempting login with NEW password (should succeed)');
    await authRobot.login(email, newPassword);
    debugPrint('Test: Waiting for Home redirect after successful login...');
    await tester.pump(const Duration(seconds: 3));
    expect(homeRobot.chatInputField, findsOneWidget);

    // Logout again
    await homeRobot.openDrawer();
    await homeRobot.tapLogout();
    await tester.pumpAndSettle();

    // --- 4. Account Recovery ---
    debugPrint('Step 4: Recovering account...');
    await authRobot.tapForgotPassword();
    await authRobot.recoverAccount(
      email: email,
      mnemonic: mnemonic,
      newPassword: recoveryPassword,
    );

    // Should auto-login after recovery
    await tester.pumpAndSettle();
    expect(homeRobot.chatInputField, findsOneWidget);

    // Verify final logout and login with recovery password
    await homeRobot.openDrawer();
    await homeRobot.tapLogout();
    await tester.pumpAndSettle();

    await authRobot.login(email, recoveryPassword);
    debugPrint('Test: Waiting for Home redirect after final login...');
    await tester.pump(const Duration(seconds: 3));
    expect(homeRobot.chatInputField, findsOneWidget);

    debugPrint('[End] E2EE Lifecycle Test Successful');
    // Final stabilization pump to avoid teardown race on Windows
    await tester.pump(const Duration(seconds: 1));
  });
}
