import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../robot/auth_robot.dart';
import '../robot/home_robot.dart';
import 'utils/e2e_test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AuthRobot auth;
  late HomeRobot home;

  setUp(() async {
    await E2ETestUtils.resetBackendState();
    await E2ETestUtils.seedAllData();
  });

  group('E2E Chat Tests', () {
    testWidgets('Guest query + real Qdrant response', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);

      await E2ETestUtils.buildE2ETestApp(tester);

      // Enter as guest
      await auth.tapGuestLogin();

      // Send a query
      await home.enterMessage('What is the true nature of reality?');
      await home.tapSend();

      // Verify the StubLLMClient canned response appears
      await home.waitForText('involves spiritual wisdom and inner peace');
 
      // Verify citations exist
      expect(home.citationByText('Inner Peace E2E test'), findsWidgets);
    });

    testWidgets('Guest rate limiting', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);

      await E2ETestUtils.buildE2ETestApp(tester);

      // Enter as guest
      await auth.tapGuestLogin();

      // AppStrings.guestQueryLimit is usually 3. Let's send 3 queries.
      for (var i = 0; i < 3; i++) {
        await home.enterMessage('Query number $i');
        await home.tapSend();
        await tester.pump(const Duration(seconds: 2)); // Wait for simulated network + animation
      }

      // 4th query should trigger limit
      await home.enterMessage('One too many');
      await home.tapSend();
      await tester.pump(const Duration(seconds: 2));

      // Verify rate limit banner appears
      expect(home.rateLimitBanner, findsOneWidget);
    });

    testWidgets('Authenticated chat persistence', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);

      await E2ETestUtils.seedTestUser('chatuser@e2e.com', 'ChatPass123!');
      await E2ETestUtils.buildE2ETestApp(tester);

      // Login
      await auth.login('chatuser@e2e.com', 'ChatPass123!');

      // Send a query
      await home.enterMessage('Hello server');
      await home.tapSend();
      
      // Wait for response
      await home.waitForText('involves spiritual wisdom');

      // Verify conversation in sidebar
      await home.openDrawer();
      expect(find.textContaining('Hello server'), findsNWidgets(3));

      // TODO: We could add a test here to swap to another conversation and back, 
      // but creating one conversation and seeing it in the drawer proves persistence 
      // is working via `loadHistory` / `getConversations`
    });

    testWidgets('Delete conversation', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);

      await E2ETestUtils.seedTestUser('delete@e2e.com', 'DeletePass123!');
      await E2ETestUtils.buildE2ETestApp(tester);

      await auth.login('delete@e2e.com', 'DeletePass123!');

      // Send a query to create conversation
      await home.enterMessage('To be deleted');
      await home.tapSend();
      await tester.pump(const Duration(seconds: 2));

      // Delete the conversation from the drawer
      await home.openDrawer();
      await tester.pumpAndSettle(); // Wait for drawer animation and list loading

      // Open settings where conversation delete actions are rendered.
      await home.tapSettings();
      await tester.pumpAndSettle();

      // Verify seeded conversation is listed first.
      expect(find.textContaining('To be deleted'), findsOneWidget);

      // Tap the per-conversation delete action and validate removal.
      final deleteAction = find.byTooltip('Delete').first;
      expect(deleteAction, findsOneWidget);
      await tester.tap(deleteAction);
      await tester.pumpAndSettle();

      expect(find.text('Conversation deleted'), findsOneWidget);
      expect(find.textContaining('To be deleted'), findsNothing);
    });
  });
}
