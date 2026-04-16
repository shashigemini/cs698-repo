import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../robot/auth_robot.dart';
import '../robot/home_robot.dart';
import '../robot/settings_robot.dart';
import 'utils/e2e_test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AuthRobot auth;
  late HomeRobot home;
  late SettingsRobot settings;

  setUp(() async {
    await E2ETestUtils.resetBackendState();
    await E2ETestUtils.seedAllData();
  });

  group('E2E Full Workflow', () {
    testWidgets('Register -> Chat -> Change Password -> Delete Account', (tester) async {
      auth = AuthRobot(tester);
      home = HomeRobot(tester);
      settings = SettingsRobot(tester);

      await E2ETestUtils.buildE2ETestApp(tester);

      // 1. Register new user
      await auth.switchToRegister();
      await auth.enterRegisterEmail('full_workflow@e2e.com');
      await auth.enterRegisterPassword('WorkflowPass123!');
      await auth.tapRegister();
      await auth.confirmMnemonic();
      expect(home.drawerButton, findsOneWidget);

      // 2. Send Chat Query
      await home.enterMessage('Can you guide my path?');
      await home.tapSend();
      await home.waitForText('involves spiritual wisdom and inner peace');

      // 3. Change Password
      await home.openDrawer();
      await home.tapSettings();
      await settings.changePassword('WorkflowPass123!', 'NewWorkflowPass123!');

      // 4. Logout & Login again
      await home.tapBack();
      await home.openDrawer();
      await home.tapLogout();
      await auth.login('full_workflow@e2e.com', 'NewWorkflowPass123!');
      expect(home.drawerButton, findsOneWidget);

      // 5. Verify conversation history persists
      await home.openDrawer();
      expect(find.textContaining('guide my path'), findsOneWidget);
      // close drawer by tapping on the right side of the screen (outside drawer)
      await tester.tapAt(Offset(tester.getSize(find.byType(Scaffold).first).width - 10, 100));
      await tester.pumpAndSettle();

      // 6. Delete Account
      await home.openDrawer();
      await home.tapSettings();
      await settings.tapDeleteAccount();
      await tester.pumpAndSettle();
      await settings.confirmDeleteAccount();
      await tester.pumpAndSettle();

      // 7. Verify Account is gone
      expect(auth.loginButton, findsOneWidget);
      await auth.login('full_workflow@e2e.com', 'NewWorkflowPass123!');
      expect(find.textContaining('Invalid email or password'), findsOneWidget);
    });
  });
}
