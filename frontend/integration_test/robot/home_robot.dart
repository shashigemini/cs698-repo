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
    await tester.enterText(chatInputField, message);
    await tester.pumpAndSettle();
  }

  Future<void> tapSend() async {
    await tester.tap(chatSendButton);
    await tester.pumpAndSettle();
  }

  Future<void> openDrawer() async {
    // Alternatively, swipe from left edge
    await tester.tap(drawerButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapNewConversation() async {
    await tester.tap(newConversationMenu);
    await tester.pumpAndSettle();
  }

  Future<void> tapLogout() async {
    await tester.ensureVisible(logoutMenu);
    await tester.tap(logoutMenu);
    await tester.pumpAndSettle();
  }

  Future<void> tapSignIn() async {
    await tester.ensureVisible(signInMenu);
    await tester.tap(signInMenu);
    await tester.pumpAndSettle();
  }

  Future<void> tapSettings() async {
    await tester.ensureVisible(settingsMenu);
    await tester.tap(settingsMenu);
    await tester.pumpAndSettle();
  }

  Future<void> tapSuggestion(String suggestionText) async {
    await tester.tap(find.text(suggestionText));
    await tester.pumpAndSettle();
  }
}
