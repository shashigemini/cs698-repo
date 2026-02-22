import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';

class MockLoggedInAuthRepo extends MockAuthRepository {
  @override
  String? get currentUser => 'test-user-id';

  @override
  Stream<String?> get authStateChanges => Stream.value('test-user-id');
}

void main() {
  testWidgets('Router redirects to Login if unauthenticated', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(),
        ), // Default is unauthenticated
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    // Fast-forward past StartupScreen's Future.delayed(2 seconds)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Unauthenticated access -> should be at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('Router redirects to Home if authenticated', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockLoggedInAuthRepo()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    // Fast-forward past StartupScreen's Future.delayed(2 seconds)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Authenticated access -> should bypass Login and go to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
