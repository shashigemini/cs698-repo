import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main_demo.dart';

void main() {
  testWidgets('Counter increments smoke test', (tester) async {
    await tester.pumpWidget(const SacredWisdomApp());
    expect(find.text('Sacred Wisdom'), findsOneWidget);
  });
}
