import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Login screen smoke test', (tester) async {
    await tester.pumpWidget(const LoginPageWrapper());
    expect(find.text('Login'), findsOneWidget);
  });
}

class LoginPageWrapper extends StatelessWidget {
  const LoginPageWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginScreen());
  }
}
