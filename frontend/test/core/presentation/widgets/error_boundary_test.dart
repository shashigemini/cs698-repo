import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/presentation/widgets/error_boundary.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('displays child when no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: Text('Safe Child'))),
      );

      expect(find.text('Safe Child'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('displays error UI when state is set manually', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorBoundary(child: Container())),
      );

      final context = tester.element(find.byType(Container));
      // Directly call static method which triggers setState in boundary
      ErrorBoundary.reportError(context, Exception('Test Error'));

      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
    });

    testWidgets('Try Again button clears error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: SizedBox.shrink())),
      );

      final context = tester.element(find.byType(SizedBox));
      ErrorBoundary.reportError(context, Exception('Test Error'));
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(find.text('Something went wrong'), findsNothing);
    });
  });
}
