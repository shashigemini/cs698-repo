import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/core/services/mock_storage_service.dart';
import 'package:frontend/core/exceptions/app_exceptions.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:logger/logger.dart';
import '../../../../helpers/crypto_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository authRepository;
  late FakeCryptographyService crypto;
  late FakeRecoveryService recovery;
  late FakeSessionKeyStore sessionKeys;
  late MockStorageService storage;

  setUpAll(() async {
    await AppLogger.init(level: Level.off);
  });

  setUp(() {
    crypto = FakeCryptographyService();
    recovery = FakeRecoveryService();
    storage = MockStorageService();
    sessionKeys = FakeSessionKeyStore();

    authRepository = MockAuthRepository(
      crypto: crypto,
      recovery: recovery,
      sessionKeys: sessionKeys,
      storage: storage,
      useDelay: false,
    );
  });

  group('Password Change', () {
    test(
      'Happy path: register -> login -> change password -> login with new',
      () async {
        const email = 'change@test.com';
        const oldPassword = 'OldPassword123!';
        const newPassword = 'NewPassword123!';

        // 1. Register
        await authRepository.register(email, oldPassword);
        await authRepository.logout();

        // 2. Login with old
        await authRepository.login(email, oldPassword);
        expect(authRepository.currentUserId, isNotNull);

        // 3. Change password
        await authRepository.changePassword(oldPassword, newPassword);
        await authRepository.logout();

        // 4. Login with old should fail
        expect(
          () => authRepository.login(email, oldPassword),
          throwsA(isA<AuthException>()),
        );

        // 5. Login with new should succeed
        await authRepository.login(email, newPassword);
        expect(authRepository.currentUserId, isNotNull);
      },
    );

    test('Old password rejected if incorrect during change', () async {
      const email = 'wrong_old@test.com';
      await authRepository.register(email, 'CorrectOld');

      expect(
        () => authRepository.changePassword('IncorrectOld', 'NewPass'),
        throwsA(isA<AuthException>()),
      );
    });

    test('Unauthenticated user cannot change password', () async {
      expect(
        () => authRepository.changePassword('any', 'any'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
