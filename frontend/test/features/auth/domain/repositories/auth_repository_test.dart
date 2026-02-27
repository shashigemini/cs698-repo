import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import '../../../../helpers/crypto_mocks.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements StorageService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TokenPair(
        accessToken: '',
        refreshToken: '',
        accessExpiresAt: DateTime.now(),
      ),
    );
  });

  group('AuthRepository (Mock)', () {
    late MockAuthRepository repository;
    late MockStorage mockStorage;

    setUp(() {
      mockStorage = MockStorage();
      // Stub the storage methods
      when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
      when(() => mockStorage.deleteTokens()).thenAnswer((_) async {});

      repository = MockAuthRepository(
        storage: mockStorage,
        crypto: FakeCryptographyService(),
        sessionKeys: MockSessionKeyStore(),
      );

      // Seed a user for login tests
      repository.seedUser('test@example.com', 'password');
    });

    test('initial state is unauthenticated (null)', () {
      expect(repository.currentUser, isNull);
    });

    test(
      'login with valid credentials updates currentUser and emits state',
      () async {
        // Subscribe before the action, then perform the action.
        final future = expectLater(
          repository.authStateChanges,
          emits('mock-user-id'),
        );

        await repository.login('test@example.com', 'password');
        await future;
        expect(repository.currentUser, 'mock-user-id');
      },
    );

    test(
      'login with invalid credentials throws Exception and state remains null',
      () async {
        expect(
          () async =>
              await repository.login('test@example.com', 'wrongpassword'),
          throwsA(isA<Exception>()),
        );

        expect(repository.currentUser, isNull);
      },
    );

    test(
      'loginAnonymously updates currentUser to guest and emits state',
      () async {
        final future = expectLater(
          repository.authStateChanges,
          emits(AppStrings.guestUserId),
        );

        await repository.loginAnonymously();
        await future;
        expect(repository.currentUser, AppStrings.guestUserId);
      },
    );

    test('logout clears currentUser and emits null state', () async {
      // First, log in
      await repository.login('test@example.com', 'password');
      expect(repository.currentUser, 'mock-user-id');

      // Subscribe, then trigger logout.
      final future = expectLater(repository.authStateChanges, emits(isNull));

      await repository.logout();
      await future;
      expect(repository.currentUser, isNull);
    });
  });
}
