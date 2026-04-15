import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/startup/presentation/startup_screen.dart';

void main() {
  testWidgets('StartupScreen displays UI and navigates after delay', (
    WidgetTester tester,
  ) async {
    // Create a real GoRouter to handle the context.go('/home') call
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen Mock')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    // Initial render checks
    expect(find.text('Sacred Wisdom'), findsOneWidget);
    expect(find.text('Your AI guide to spiritual texts'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.message), findsOneWidget);

    // Fast-forward time to let the Future.delayed(2 seconds) execute
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that we've navigated to the mocked Home screen
    expect(find.text('Home Screen Mock'), findsOneWidget);
  });
}
