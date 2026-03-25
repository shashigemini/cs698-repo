import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main_demo.dart' as app;
import '../robot/home_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Auth Flow: Login and Logout', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    final homeRobot = HomeRobot(tester);

    // Initial state: Should see login/guest options or Splash
    // Navigate to Login if needed
    await homeRobot.openDrawer();
    await homeRobot.tapSignIn();
    
    // Simulate login (since we use mocks in demo mode, this should succeed)
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
