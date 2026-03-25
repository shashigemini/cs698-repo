import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/presentation/widgets/chat_input_field.dart';

void main() {
  testWidgets('Chat input field smoke test', (tester) async {
    var sent = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatInputField(onSend: (_) => sent = true),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send));
    expect(sent, isTrue);
  });
}
