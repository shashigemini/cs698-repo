import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility: Core Components', () {
    testWidgets('ElevatedButtons satisfy WCAG contrast and tap target guidelines', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();

      // We'll test a generic ElevatedButton, which the app uses for significant actions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors
                      .teal[800], // Darkened to meet WCAG AA contrast (>= 4.5:1) against white text
                  foregroundColor: Colors.white,
                ),
                child: const Text('Primary Action'),
              ),
            ),
          ),
        ),
      );

      // Verify Contrast
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      // Verify tap target size (Android requires 48x48, iOS requires 44x44)
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      // Verify Semantics label exists
      expect(
        tester.getSemantics(find.byType(ElevatedButton)),
        matchesSemantics(
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          label: 'Primary Action',
        ),
      );

      handle.dispose();
    });

    testWidgets(
      'IconButtons satisfy WCAG tap target and semantic label guidelines',
      (WidgetTester tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  tooltip: 'Share item', // This provides the semantic label
                ),
              ),
            ),
          ),
        );

        // Verify tap target size
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        // Verify Semantics label (provided by tooltip)
        expect(
          tester.getSemantics(find.byType(IconButton)),
          matchesSemantics(
            isButton: true,
            hasTapAction: true,
            hasFocusAction: true,
            isEnabled: true,
            hasEnabledState: true,
            isFocusable: true,
            tooltip: 'Share item',
          ),
        );

        handle.dispose();
      },
    );
  });
}
