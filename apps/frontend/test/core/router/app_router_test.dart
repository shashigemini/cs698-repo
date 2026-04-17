import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';

import 'package:frontend/core/services/storage_service.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import '../../helpers/crypto_mocks.dart';

class MockStorage extends Mock implements StorageService {}

class MockLoggedInAuthRepo extends MockAuthRepository {
  MockLoggedInAuthRepo({
    required super.storage,
    required super.crypto,
    required super.sessionKeys,
    required super.recovery,
  });

  @override
  String? get currentUserId => 'test-user-id';

  @override
  Stream<String?> get authStateChanges => Stream.value('test-user-id');
}

class DelayedInitAuthRepo extends MockAuthRepository {
  DelayedInitAuthRepo({
    required super.storage,
    required super.crypto,
    required super.sessionKeys,
    required super.recovery,
    required this.initCompleter,
    this.restoredUserId,
  });

  final Completer<void> initCompleter;
  final String? restoredUserId;
  final StreamController<String?> _streamController =
      StreamController<String?>.broadcast();

  @override
  Stream<String?> get authStateChanges => _streamController.stream;

  @override
  Future<void> initializeSession() async {
    await initCompleter.future;
    setUser(restoredUserId);
    _streamController.add(restoredUserId);
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Router redirects to Login if unauthenticated', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(
            storage: MockStorage(),
            crypto: FakeCryptographyService(),
            sessionKeys: MockSessionKeyStore(),
            recovery: MockRecoveryService(),
          ),
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
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          MockLoggedInAuthRepo(
            storage: MockStorage(),
            crypto: FakeCryptographyService(),
            sessionKeys: MockSessionKeyStore(),
            recovery: MockRecoveryService(),
          ),
        ),
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

  testWidgets(
    'Router does not redirect to login/home until restore finishes',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final initCompleter = Completer<void>();
      final delayedRepo = DelayedInitAuthRepo(
        storage: MockStorage(),
        crypto: FakeCryptographyService(),
        sessionKeys: MockSessionKeyStore(),
        recovery: MockRecoveryService(),
        initCompleter: initCompleter,
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(delayedRepo),
        ],
      );
      addTearDown(() {
        delayedRepo.dispose();
        container.dispose();
      });

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

      // Startup tries to navigate after 2s, but auth initialization is pending.
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Sacred Wisdom'), findsOneWidget);

      // Completing restore should allow the router to make the auth decision.
      initCompleter.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    },
  );
}
