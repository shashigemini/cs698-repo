import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main_demo.dart' as app;
import '../robot/home_robot.dart';
import '../robot/settings_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Full Workflow: Chat -> Settings -> Logout', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    final homeRobot = HomeRobot(tester);
    final settingsRobot = SettingsRobot(tester);

    // 1. Chat
    await homeRobot.enterMessage('What is dharma?');
    await homeRobot.tapSend();
    await homeRobot.waitForText('dharma');

    // 2. Settings
    await homeRobot.openDrawer();
    await homeRobot.tapSettings();
    await tester.pumpAndSettle();
    
    expect(find.text('Account Settings'), findsOneWidget);
    await settingsRobot.enterSearch('dharma');
    
    // 3. Logout
    await homeRobot.tapBack();
    await homeRobot.openDrawer();
    await homeRobot.tapLogout();
    await tester.pumpAndSettle();
    
    expect(find.text('Login'), findsOneWidget);
  });
}
