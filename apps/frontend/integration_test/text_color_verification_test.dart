import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'robot/auth_robot.dart';
import 'robot/home_robot.dart';
import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    debugPrint('Wiping storage for test isolation...');
    await wipeStorage();
  });

  testWidgets('Verify input text color is black when typing', (tester) async {
    debugPrint('[Start] Verify input text color is black when typing');
    await buildTestApp(tester);

    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);

    // Initial wait for app to load
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    debugPrint('Checking Login Screen fields...');

    // Verify Email field color
    final emailField = tester.widget<TextField>(authRobot.emailField);
    expect(
      emailField.style?.color,
      Colors.black,
      reason: 'Email field text should be black',
    );

    // Verify Password field color
    final passwordField = tester.widget<TextField>(authRobot.passwordField);
    expect(
      passwordField.style?.color,
      Colors.black,
      reason: 'Password field text should be black',
    );

    debugPrint('Navigating to Home Screen as Guest...');
    await authRobot.tapGuestLogin();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    debugPrint('Checking Home Screen chat input field...');

    // Verify Chat input field color
    final chatInputField = tester.widget<TextField>(homeRobot.chatInputField);
    expect(
      chatInputField.style?.color,
      Colors.black,
      reason: 'Chat input field text should be black',
    );

    debugPrint('All input fields verified to have black text color.');
  });
}
