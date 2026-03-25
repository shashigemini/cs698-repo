import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main_demo.dart' as app;
import '../robot/home_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Chat Flow: Send message and get response', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    final homeRobot = HomeRobot(tester);

    // Send a message
    await homeRobot.enterMessage('How can I find peace?');
    await homeRobot.tapSend();
    
    // Wait for response
    await homeRobot.waitForText('spiritual');
    expect(find.textContaining('How can I find peace?'), findsOneWidget);
  });
}
