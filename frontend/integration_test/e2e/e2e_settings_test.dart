import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main_demo.dart' as app;
import '../robot/home_robot.dart';
import '../robot/settings_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Settings Flow: Search history', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    final homeRobot = HomeRobot(tester);
    final settingsRobot = SettingsRobot(tester);

    // Navigate to settings
    await homeRobot.openDrawer();
    await homeRobot.tapSettings();
    
    // Search
    await settingsRobot.enterSearch('Gita');
    await tester.pumpAndSettle();
  });
}
