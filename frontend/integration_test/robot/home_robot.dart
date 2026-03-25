import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class HomeRobot {
  final WidgetTester tester;

  HomeRobot(this.tester);

  // Finders
  Finder get chatInputField => find.byType(TextField).first;
  Finder get chatSendButton => find.byIcon(LucideIcons.send);
  Finder get drawerButton => find.byIcon(LucideIcons.menu);
  
  // Drawer items
  Finder get signInMenu => find.text('Sign In / Register');
  Finder get logoutMenu => find.text('Logout');
  Finder get settingsMenu => find.text('Account Settings');
  Finder get newConversationMenu => find.text('New Conversation');

  // Actions
  Future<void> enterMessage(String message) async {
    debugPrint('Robot: Entering message: \"\$message\"');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(chatInputField, message);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapSend() async {
    debugPrint('Robot: Tapping Send button');
    await tester.tap(chatSendButton);
    // Avoid pumpAndSettle here: once send triggers, the TypingIndicator
    // animation is infinite and pumpAndSettle will hang. Use bounded pump.
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> openDrawer() async {
    debugPrint('Robot: Opening Side Drawer');
    await tester.tap(drawerButton);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapNewConversation() async {
    debugPrint('Robot: Tapping New Conversation menu');
    await tester.tap(newConversationMenu);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapLogout() async {
    debugPrint('Robot: Tapping Logout menu');
    await tester.ensureVisible(logoutMenu);
    await tester.tap(logoutMenu);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapSignIn() async {
    debugPrint('Robot: Tapping Sign In menu');
    await tester.ensureVisible(signInMenu);
    await tester.tap(signInMenu);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapSettings() async {
    debugPrint('Robot: Tapping Account Settings menu');
    await tester.ensureVisible(settingsMenu);
    await tester.tap(settingsMenu);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapBack() async {
    debugPrint('Robot: Tapping Back button');
    await tester.tap(find.byType(BackButton).first);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> waitForText(String text,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (tester.any(find.textContaining(text))) {
        debugPrint(
            'Robot: Found expected text \"\$text\" after \${stopwatch.elapsedMilliseconds}ms');
        return;
      }
      if (stopwatch.elapsedMilliseconds % 1000 == 0) {
        debugPrint(
            'Robot: Still waiting for \"\$text\" (\${stopwatch.elapsed.inSeconds}s)...');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    debugPrint(
        'Robot: Timed out! Current UI finding for partial \"involves spiritual\":');
    try {
      final matches = find.textContaining('involves spiritual').evaluate();
      debugPrint('Robot: Matches found: \${matches.length}');
      for (final m in matches) {
        debugPrint('Robot: Match content: \${(m.widget as Text).data}');
      }
    } catch (e) {
      debugPrint('Robot: Error during debug dump: \$e');
    }
    throw TestFailure('Timed out waiting for text: \"\$text\"');
  }

  Future<void> tapSuggestion(String suggestionText) async {
    debugPrint('Robot: Tapping suggestion: \"\$suggestionText\"');
    await tester.tap(find.text(suggestionText));
    // Avoid pumpAndSettle: suggestion triggers TypingIndicator
    // which has an infinite animation (project rule 3.3).
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapConversation(String title) async {
    debugPrint('Robot: Tapping conversation with title: \"\$title\"');
    final conversationItem = find.textContaining(title);
    await tester.ensureVisible(conversationItem);
    await tester.tap(conversationItem);
    // Wait for history to load (messages removed, then new ones appear)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<void> expectMessageToAppear(String text,
      {int timeoutSeconds = 5}) async {
    final finder = find.textContaining(text);
    var seconds = 0;
    while (tester.any(finder) == false && seconds < timeoutSeconds) {
      debugPrint('Robot: Waiting for message \"\$text\"...');
      await tester.pump(const Duration(seconds: 1));
      seconds++;
    }
    expect(finder, findsAtLeastNWidgets(1),
        reason: 'Message \"\$text\" did not appear after \${timeoutSeconds}s');
  }
}
