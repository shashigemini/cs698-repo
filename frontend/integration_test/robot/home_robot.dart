import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class HomeRobot {
  final WidgetTester tester;

  HomeRobot(this.tester);

  // Finders
  Finder get chatInputField => find.byKey(const Key('chat_input_field'));
  Finder get chatSendButton => find.byKey(const Key('chat_send_button'));
  Finder get drawerButton => find.byTooltip('Open navigation menu');
  Finder get newConversationMenu => find.text('New Conversation');
  Finder get logoutMenu => find.byKey(const Key('logout_menu_item'));
  Finder get signInMenu => find.text('Sign In / Register');
  Finder get settingsMenu => find.text('Account Settings');
  Finder get rateLimitBanner => find.byKey(const Key('rate_limit_banner'));
  Finder get shareButton => find.byIcon(LucideIcons.share2);
  Finder citationByText(String text) => find.textContaining(text);
  Finder get citationBottomSheet => find.text('Scripture Verse');

  // Actions
  Future<void> enterMessage(String message) async {
    // Per project rule 3.7: tap first to ensure focus on Windows,
    // then enterText. Avoid pumpAndSettle which can hang on chat animations.
    await tester.tap(chatInputField);
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

  Future<void> tapSuggestion(String suggestionText) async {
    debugPrint('Robot: Tapping suggestion: "$suggestionText"');
    await tester.tap(find.text(suggestionText));
    // Avoid pumpAndSettle: suggestion triggers TypingIndicator
    // which has an infinite animation (project rule 3.3).
    await tester.pump(const Duration(milliseconds: 100));
  }
}
