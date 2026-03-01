import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/core/services/recovery_service.dart';
import 'package:frontend/core/services/mock_storage_service.dart';
import 'package:frontend/core/exceptions/app_exceptions.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:logger/logger.dart';
import '../../../../helpers/crypto_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository authRepository;
  late FakeCryptographyService crypto;
  late RecoveryService recovery;
  late FakeSessionKeyStore sessionKeys;
  late MockStorageService storage;

  setUpAll(() async {
    await AppLogger.init(level: Level.off);
  });

  setUp(() {
    crypto = FakeCryptographyService();
    recovery = RecoveryService(); // Use real service for mnemonic logic
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

  group('Account Recovery', () {
    test(
      'Happy path: register -> get mnemonic -> recover with new password',
      () async {
        const email = 'recover@test.com';
        const oldPassword = 'OldPassword123!';
        const newPassword = 'Recovered123!';

        // 1. Register and capture mnemonic
        final mnemonic = await authRepository.register(email, oldPassword);
        expect(mnemonic.split(' ').length, 16);
        await authRepository.logout();

        // 2. Recover account
        await authRepository.recoverAccount(
          email: email,
          mnemonic: mnemonic,
          newPassword: newPassword,
        );

        // Auto-login should happen after recovery
        expect(authRepository.currentUserId, isNotNull);
        await authRepository.logout();

        // 3. Login with new password
        await authRepository.login(email, newPassword);
        expect(authRepository.currentUserId, isNotNull);

        // 4. Old password should fail
        await authRepository.logout();
        expect(
          () => authRepository.login(email, oldPassword),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('Recovery fails with invalid mnemonic', () async {
      const email = 'bad_mnemonic@test.com';
      await authRepository.register(email, 'Pass123');
      await authRepository.logout();

      expect(
        () => authRepository.recoverAccount(
          email: email,
          mnemonic: 'invalid mnemonic words here',
          newPassword: 'NewPassword',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Recovery for non-existent email fails', () async {
      expect(
        () => authRepository.recoverAccount(
          email: 'nonexistent@test.com',
          mnemonic: List.filled(16, 'abandon').join(' '),
          newPassword: 'NewPassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
