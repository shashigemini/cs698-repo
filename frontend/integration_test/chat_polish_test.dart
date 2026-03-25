import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'robot/auth_robot.dart';
import 'robot/home_robot.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    debugPrint('Wiping storage for test isolation...');
    await wipeStorage();
  });

  late AuthRobot authRobot;
  late HomeRobot homeRobot;

  group('Chat Polish Integration Test', () {
    Future<void> startApp(WidgetTester tester) async {
      await buildTestApp(tester);
      authRobot = AuthRobot(tester);
      homeRobot = HomeRobot(tester);
    }

    testWidgets('History Loading, Sharing, and Citations', (tester) async {
      await startApp(tester);

      // 1. Login
      await authRobot.login('test@example.com', 'password');
      // Login triggers router redirect + fetchRecentConversations (500ms mock)
      // Use pump to advance past async delays, then bounded pumpAndSettle
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      // 2. Open Drawer and check History Item
      await homeRobot.openDrawer();
      final historyItem = find.text('What is karma?');
      expect(historyItem, findsOneWidget);

      // 3. Load Conversation from History
      await tester.tap(historyItem);
      // Wait for history fetch simulation (500ms in mock repo)
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify history content loaded
      expect(find.text('Hi! How can I help?'), findsOneWidget);

      // 4. Send new query and check polish features
      await homeRobot.enterMessage('Tell me about dharma');
      await homeRobot.tapSend();

      // Wait for AI response simulation (1s in mock repo)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify Share Button is present
      expect(find.byIcon(LucideIcons.share2), findsAtLeastNWidgets(1));

      // Verify Interactive Citation
      final citation = find.textContaining('Mock Doc (p. 1)').first;
      expect(citation, findsOneWidget);

      // Tap Citation to open Scripture View
      await tester.tap(citation);
      await tester.pumpAndSettle();

      // Verify Bottom Sheet
      expect(find.text('Scripture Verse'), findsOneWidget);
      expect(find.textContaining('The soul is neither born'), findsOneWidget);

      // Close Sheet
      await tester.tap(find.byIcon(LucideIcons.x).last);
      await tester.pumpAndSettle();
    });

    testWidgets('Guest Limit Label consistency', (tester) async {
      await startApp(tester);

      // Explicitly login as guest
      await authRobot.tapGuestLogin();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify "3 queries" is present in the drawer
      await homeRobot.openDrawer();
      expect(find.textContaining('queries remaining'), findsOneWidget);
      expect(find.textContaining('10 queries'), findsNothing);

      // Verification of actual rate limiting is already covered in app_test.dart
    });
  });
}
