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

  group('E2E Auth Tests', () {
    testWidgets('Registration Flow', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);

      await E2ETestUtils.buildE2ETestApp(tester);

      // Register new user
      await auth.switchToRegister();
      await auth.enterRegisterEmail('newuser@e2e.com');
      await auth.enterRegisterPassword('SecurePass123!');
      await auth.tapRegister();

      // Verify mnemonic dialog appears, then confirm
      await auth.confirmMnemonic();

      // Should land on home screen
      expect(home.drawerButton, findsOneWidget);
    });

    testWidgets('Login Flow with Seeded User', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);

      // Pre-seed an actual test user via the backend endpoint
      await E2ETestUtils.seedTestUser('seeded@e2e.com', 'SeededPass123!');

      await E2ETestUtils.buildE2ETestApp(tester);

      // Perform login
      await auth.login('seeded@e2e.com', 'SeededPass123!');

      // Should land on home screen
      await tester.pumpAndSettle();
      expect(home.drawerButton, findsOneWidget);
    });

    testWidgets('Invalid Credentials', (tester) async {
      auth = AuthRobot(tester);
      await E2ETestUtils.buildE2ETestApp(tester);

      // Perform login with wrong password
      await auth.login('seeded@e2e.com', 'WrongPassword123!');

      // Should still be on auth screen with error indicating invalid credentials
      await tester.pump(const Duration(milliseconds: 1000)); // Extra time for SnackBar
      expect(auth.loginButton, findsOneWidget);
      expect(find.textContaining('Invalid email or password'), findsOneWidget);
    });

    testWidgets('Logout Redirect', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);

      await E2ETestUtils.seedTestUser('logout@e2e.com', 'LogoutPass123!');
      await E2ETestUtils.buildE2ETestApp(tester);

      // Login first
      await auth.login('logout@e2e.com', 'LogoutPass123!');
      await tester.pumpAndSettle();
      expect(home.drawerButton, findsOneWidget);

      // Open drawer and tap sign out
      await home.openDrawer();
      await home.tapLogout();

      // Should land back on auth screen
      expect(auth.loginButton, findsOneWidget);
    });
  });
}
