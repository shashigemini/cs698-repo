import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart' as app;

import 'robot/auth_robot.dart';
import 'robot/home_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    debugPrint(
      'Wiping secure storage & shared preferences for test isolation...',
    );
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('Full Guest Flow - Chat, Drawer, and Sign In routing', (
    tester,
  ) async {
    debugPrint('[Start] Full Guest Flow - Chat, Drawer, and Sign In routing');
    app.main();
    await tester.pumpAndSettle();

    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);

    debugPrint('Pump and settle initial startup...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    debugPrint('Tapping Guest Login...');
    await authRobot.tapGuestLogin();

    debugPrint('Waiting for Home view navigation...');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(homeRobot.chatInputField, findsOneWidget);

    debugPrint('Tapping suggestion string...');
    await homeRobot.tapSuggestion(
      'What does the Bhagavad Gita teach about karma?',
    );

    debugPrint('Waiting for system response propagation...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(
      find.text('What does the Bhagavad Gita teach about karma?'),
      findsOneWidget,
    );

    debugPrint('Opening Drawer...');
    await homeRobot.openDrawer();
    debugPrint('Tapping New Conversation...');
    await homeRobot.tapNewConversation();

    debugPrint('Re-opening Drawer...');
    await homeRobot.openDrawer();
    debugPrint('Tapping Sign In...');
    await homeRobot.tapSignIn();

    debugPrint('Waiting for router redirect to login...');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(authRobot.loginButton, findsOneWidget);
    debugPrint('Done. Pumping trailing frame buffer...');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    debugPrint('[End] Full Guest Flow');
  });

  testWidgets('Invalid Login and Registration validations', (tester) async {
    debugPrint('[Start] Invalid Login and Registration validations');
    app.main();
    await tester.pumpAndSettle();

    final authRobot = AuthRobot(tester);

    debugPrint('Pump initial view...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    debugPrint('Tapping login with empty fields...');
    await authRobot.tapLogin();
    expect(find.text('Email is required'), findsWidgets);

    debugPrint('Clearing snackbars...');
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    debugPrint('Entering invalid email...');
    await authRobot.enterEmail('invalid_email');
    await authRobot.enterPassword('password');
    await authRobot.tapLogin();

    expect(find.text('Enter a valid email address'), findsWidgets);

    debugPrint('Clearing snackbars...');
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    debugPrint('Switching to Register tab...');
    await authRobot.switchToRegister();

    debugPrint('Entering weak register password...');
    await authRobot.enterRegisterEmail('test@test.com');
    await authRobot.enterRegisterPassword('weak');
    await authRobot.tapRegister();

    expect(find.textContaining('8 characters'), findsWidgets);
    debugPrint('Done. Pumping trailing frame buffer...');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    debugPrint('[End] Invalid Login and Registration validations');
  });

  testWidgets('Authenticated User Flow with Login, Message Send and Logout', (
    tester,
  ) async {
    debugPrint('[Start] Authenticated User Flow');
    app.main();
    await tester.pumpAndSettle();

    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);

    debugPrint('Pump initial startup...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    debugPrint('Entering auth credentials...');
    await authRobot.enterEmail('test@example.com');
    await authRobot.enterPassword('password');
    debugPrint('Tapping login array...');
    await authRobot.tapLogin();

    debugPrint('Waiting 5s for network login simulation & nav...');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(homeRobot.chatInputField, findsOneWidget);

    debugPrint('Typing text into input field...');
    await homeRobot.enterMessage('Hello Sacred Wisdom');
    debugPrint('Tapping send...');
    await homeRobot.tapSend();

    debugPrint('Waiting for response propagation...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Hello Sacred Wisdom'), findsOneWidget);

    debugPrint('Opening drawer...');
    await homeRobot.openDrawer();
    debugPrint('Tapping logout...');
    await homeRobot.tapLogout();

    debugPrint('Waiting for redirect...');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(authRobot.loginButton, findsOneWidget);
    debugPrint('Done. Pumping trailing frame buffer...');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    debugPrint('[End] Authenticated User Flow');
  });

  testWidgets('Rate Limit Exceeded and Network Error UI Flow', (tester) async {
    debugPrint('[Start] Rate Limit Exceeded Flow');
    app.main();
    await tester.pumpAndSettle();

    final authRobot = AuthRobot(tester);
    final homeRobot = HomeRobot(tester);

    debugPrint('Waiting for startup to finish...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final loginScreenFound = find
        .byKey(const Key('login_button'))
        .evaluate()
        .isNotEmpty;
    debugPrint('Is Login screen visible at start: $loginScreenFound');

    if (loginScreenFound) {
      debugPrint('Tapping guest login...');
      await authRobot.tapGuestLogin();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    } else {
      debugPrint('WARNING: Login screen not visible, starting logged in!');
    }

    // Send messages to trigger RateLimitException.
    for (var i = 0; i < 4; i++) {
      debugPrint('--- Loop $i start ---');
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(homeRobot.chatInputField);
      await tester.pump();
      await tester.enterText(homeRobot.chatInputField, 'Rate limit test $i');
      await tester.pump();
      await tester.tap(homeRobot.chatSendButton);
      await tester.pump();
      debugPrint('--- Loop $i end ---');
    }

    debugPrint('Waiting for final rate limit error propagation...');
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rate_limit_banner')), findsWidgets);
    debugPrint('Rate limit banner successfully found.');

    final signInButton = find.byKey(const Key('signin_from_modal_button'));
    if (signInButton.evaluate().isNotEmpty) {
      debugPrint('Tapping sign in from modal...');
      await tester.tap(signInButton);
    } else {
      debugPrint('Fallback: tap sign in from drawer...');
      await homeRobot.openDrawer();
      await homeRobot.tapSignIn();
    }

    debugPrint('Waiting for auth view router...');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(authRobot.loginButton, findsOneWidget);
    debugPrint('Done. Pumping trailing frame buffer...');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    debugPrint('[End] Rate Limit Exceeded Flow');
  });

  testWidgets('Full Registration and Password Visibility Flow', (tester) async {
    debugPrint('[Start] Full Registration and Password Visibility Flow');
    app.main();
    await tester.pumpAndSettle();

    final authRobot = AuthRobot(tester);

    debugPrint('Waiting for start up...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    debugPrint('Switching to Register tab...');
    await authRobot.switchToRegister();

    final visibilityIcon = find.byKey(
      const Key('register_password_visibility'),
    );
    if (visibilityIcon.evaluate().isNotEmpty) {
      debugPrint('Tapping password visibility...');
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();
    }

    debugPrint('Testing Medium password collision...');
    await authRobot.enterRegisterEmail('existing@test.com');
    await authRobot.enterRegisterPassword('Medium123');
    await tester.pumpAndSettle();
    expect(find.text('Medium'), findsWidgets);

    debugPrint('Testing Strong password indicator...');
    await authRobot.enterRegisterPassword('StrongP@ssw0rd1!');
    await tester.pumpAndSettle();
    expect(find.text('Strong'), findsWidgets);

    debugPrint('Tapping register (simulating existing collision)...');
    await authRobot.tapRegister();

    debugPrint('Waiting for collision rejection response...');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.text('An account with this email already exists'),
      findsWidgets,
    );

    debugPrint('Clearing snackbar...');
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    debugPrint('Entering non-collision email (new@test)...');
    await authRobot.enterRegisterEmail('new@test.com');
    debugPrint('Tapping register (simulating success)...');
    await authRobot.tapRegister();

    debugPrint('Waiting for register redirect to home screen...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final homeRobot = HomeRobot(tester);
    expect(homeRobot.chatInputField, findsOneWidget);

    debugPrint('Test successful. Pumping trailing frame buffer...');
    // Extended the pump to 5 seconds to guarantee ALL routing animations settle
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    debugPrint('[End] Full Registration and Password Visibility Flow');
  });
}
