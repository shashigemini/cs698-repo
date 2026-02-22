import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;

import 'robot/auth_robot.dart';
import 'robot/home_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Guest Flow - Chat, Drawer, and Sign In routing', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await authRobot.tapGuestLogin();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(homeRobot.chatInputField, findsOneWidget);

    await homeRobot.tapSuggestion(
      'What does the Bhagavad Gita teach about karma?',
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(
      find.text('What does the Bhagavad Gita teach about karma?'),
      findsOneWidget,
    );

    await homeRobot.openDrawer();
    await homeRobot.tapNewConversation();

    await homeRobot.openDrawer();
    await homeRobot.tapSignIn();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(authRobot.loginButton, findsOneWidget);
  });

  testWidgets('Invalid Login and Registration validations', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    final authRobot = AuthRobot(tester);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await authRobot.tapLogin();
    expect(find.text('Email is required'), findsWidgets);

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await authRobot.enterEmail('invalid_email');
    await authRobot.enterPassword('password');
    await authRobot.tapLogin();

    expect(find.text('Enter a valid email address'), findsWidgets);

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await authRobot.switchToRegister();

    await authRobot.enterRegisterEmail('test@test.com');
    await authRobot.enterRegisterPassword('weak');
    await authRobot.tapRegister();

    expect(find.textContaining('8 characters'), findsWidgets);
  });

  testWidgets('Authenticated User Flow with Login, Message Send and Logout', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await authRobot.enterEmail('test@example.com');
    await authRobot.enterPassword('password');
    await authRobot.tapLogin();

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Verify chat field is there to trigger widget tree dump on failure
    expect(homeRobot.chatInputField, findsOneWidget);

    await homeRobot.enterMessage('Hello Sacred Wisdom');
    await homeRobot.tapSend();

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Hello Sacred Wisdom'), findsOneWidget);

    await homeRobot.openDrawer();
    await homeRobot.tapLogout();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(authRobot.loginButton, findsOneWidget);
  });

  testWidgets('Rate Limit Exceeded and Network Error UI Flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Ensure we start at Login
    final loginScreenFound = find
        .byKey(const Key('login_button'))
        .evaluate()
        .isNotEmpty;
    print('Is Login screen visible at start: $loginScreenFound');

    if (loginScreenFound) {
      print('Tapping guest login...');
      await authRobot.tapGuestLogin();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    } else {
      print('WARNING: Login screen not visible, starting logged in!');
    }

    // Send messages to trigger RateLimitException.
    // MockChatRepository limit is 3 (throws on >= 3rd guest query).
    // Messages 0 and 1 succeed; message 2 triggers the exception.
    for (int i = 0; i < 3; i++) {
      print('--- Loop $i start ---');

      // Wait for any pending async work to finish
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap field to gain focus (required after widget tree changes)
      await tester.tap(homeRobot.chatInputField);
      await tester.pump();

      // Enter text into focused field
      await tester.enterText(homeRobot.chatInputField, 'Rate limit test $i');
      await tester.pump();

      // Tap send button
      await tester.tap(homeRobot.chatSendButton);
      await tester.pump();

      print('--- Loop $i end ---');
    }

    // Wait for the final rate limit error to propagate
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Debug output if rate limit banner is missing
    if (find.byKey(const Key('rate_limit_banner')).evaluate().isEmpty) {
      print('Rate limit banner not found after 3 messages.');
      print(
        'Messages on screen: '
        '${tester.widgetList(find.byType(Text)).map((w) => (w as Text).data).join(', ')}',
      );
    }

    // Expect rate limit exceeded banner
    expect(find.byKey(const Key('rate_limit_banner')), findsWidgets);

    // Dismiss the rate limit modal if shown, then sign in
    final signInButton = find.byKey(const Key('signin_from_modal_button'));
    if (signInButton.evaluate().isNotEmpty) {
      await tester.tap(signInButton);
    } else {
      // Fallback: tap sign in from drawer
      await homeRobot.openDrawer();
      await homeRobot.tapSignIn();
    }

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify routed to login/register
    expect(authRobot.loginButton, findsOneWidget);
  });

  testWidgets('Full Registration and Password Visibility Flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    final authRobot = AuthRobot(tester);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await authRobot.switchToRegister();

    // Test password visibility toggle
    final visibilityIcon = find.byKey(
      const Key('register_password_visibility'),
    );
    if (visibilityIcon.evaluate().isNotEmpty) {
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();
    }

    await authRobot.enterRegisterEmail('existing@test.com');
    await authRobot.enterRegisterPassword('Medium123');
    await tester.pumpAndSettle();
    expect(find.text('Medium'), findsWidgets);

    await authRobot.enterRegisterPassword('StrongP@ssw0rd1!');
    await tester.pumpAndSettle();
    expect(find.text('Strong'), findsWidgets);

    await authRobot.tapRegister();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.text('An account with this email already exists.'),
      findsWidgets,
    );

    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await authRobot.enterRegisterEmail('new@test.com');
    await authRobot.tapRegister();

    // Verify routing to home screen upon successful registration
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final homeRobot = HomeRobot(tester);
    expect(homeRobot.chatInputField, findsOneWidget);
  });
}
