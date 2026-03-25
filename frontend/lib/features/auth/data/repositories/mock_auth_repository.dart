import 'dart:async';
import 'package:cryptography/cryptography.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/cryptography_service.dart';
import '../../../../core/services/session_key_store.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/recovery_service.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/token_pair.dart';
import '../../domain/repositories/auth_repository.dart';

/// Development stub for [AuthRepository] with E2EE support.
class MockAuthRepository implements AuthRepository {
  final StorageService _storage;
  final CryptographyService _crypto;
  final SessionKeyStore _sessionKeys;
  final RecoveryService _recovery;
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  String? _currentUser;
  String? _currentEmail;

  // Mock server-side storage for E2EE metadata
  final Map<String, _MockUserE2EE> _mockServerDb = {};

  final bool _useDelay;

  Future<void>? _initDefaults;

  /// Creates a [MockAuthRepository].
  MockAuthRepository({
    required StorageService storage,
    required CryptographyService crypto,
    required SessionKeyStore sessionKeys,
    required RecoveryService recovery,
    bool useDelay = true,
  }) : _storage = storage,
       _crypto = crypto,
       _sessionKeys = sessionKeys,
       _recovery = recovery,
       _useDelay = useDelay {
    _currentUser = null;
    _controller.add(_currentUser);
    _initDefaults = _seedDefaults();
    AppLogger.d('MockAuthRepository: Initialized (delays: $_useDelay)');
  }

  Future<void> _seedDefaults() async {
    // Seed common test users synchronously (or at least start the process)
    await seedUser('test@example.com', 'password');
    await seedUser('existing@test.com', 'Medium123');
    AppLogger.d('MockAuthRepository: Default users seeded');
  }

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  String? get currentUserId => _currentUser;

  @override
  Future<void> login(String email, String password) async {
    AppLogger.i('MockAuthRepository: E2EE Login Attempt');
    await _initDefaults;
    await Future<void>.delayed(const Duration(seconds: 1));

    final mockUser = _mockServerDb[email];
    if (mockUser == null) {
      throw const AuthException(
        AppStrings.invalidCredentials,
        code: 'INVALID_CREDENTIALS',
      );
    }

    // 1. Derive LMK on client
    final lmk = await _crypto.deriveLocalMasterKey(password, mockUser.salt);

    // 2. Derive ClientAuthToken
    final authToken = await _crypto.deriveAuthToken(lmk);

    // 3. Verify Auth Token (Mocking server-side check)
    if (authToken != mockUser.clientAuthToken) {
      throw const AuthException(
        AppStrings.invalidCredentials,
        code: 'INVALID_CREDENTIALS',
      );
    }

    // 4. Decrypt Account Key on client
    final ak = await _crypto.unwrapKey(mockUser.wrappedAk, lmk);

    // 5. Establish Session
    if (email == 'test@example.com') {
      _currentUser = 'mock-user-id';
    } else {
      _currentUser = 'mock-user-${email.hashCode}';
    }
    _currentEmail = email;
    _sessionKeys.setMasterKey(lmk);
    _sessionKeys.setAccountKey(ak);

    await _storage.saveTokens(
      TokenPair(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    _controller.add(_currentUser);
    AppLogger.i('MockAuthRepository: E2EE Login Successful');
  }

  @override
  Future<String> register(String email, String password) async {
    AppLogger.i('MockAuthRepository: E2EE Register Attempt');
    await _initDefaults;
    await Future<void>.delayed(const Duration(seconds: 1));

    if (_mockServerDb.containsKey(email)) {
      throw const AuthException(
        'An account with this email already exists',
        code: 'EMAIL_ALREADY_EXISTS',
      );
    }

    // 1. Generate random Salt
    final salt = List<int>.generate(16, (i) => i);

    // 2. Derive LMK
    final lmk = await _crypto.deriveLocalMasterKey(password, salt);

    // 3. Derive ClientAuthToken
    final authToken = await _crypto.deriveAuthToken(lmk);

    // 4. Generate random AccountKey
    final ak = await _crypto.generateRandomKey();

    // 5. Wrap AK with LMK
    final wrappedAk = await _crypto.wrapKey(ak, lmk);

    // 6. Recovery: Generate RK and wrap AK with it
    final rk = await _recovery.generateRecoveryKey();
    final rkBytes = await rk.extractBytes();
    final expandedRk = await _crypto.expandKey(rk);
    final recoveryWrappedAk = await _crypto.wrapKey(ak, expandedRk);
    final recoveryMnemonic = _recovery.keyToMnemonic(rkBytes);

    // 7. "Save" to mock server
    _mockServerDb[email] = _MockUserE2EE(
      salt: salt,
      clientAuthToken: authToken,
      wrappedAk: wrappedAk,
      recoveryWrappedAk: recoveryWrappedAk,
    );

    // 8. Establish Session (BUT DON'T EMIT TO CONTROLLER YET)
    _currentUser = 'new-mock-user-${email.hashCode}';
    _currentEmail = email;
    _sessionKeys.setMasterKey(lmk);
    _sessionKeys.setAccountKey(ak);

    await _storage.saveTokens(
      TokenPair(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    AppLogger.i('MockAuthRepository: E2EE Register Successful');
    return recoveryMnemonic;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    AppLogger.i('MockAuthRepository: E2EE Change Password Attempt');
    if (_currentUser == null || _currentEmail == null) {
      throw const AuthException('Not authenticated', code: 'NOT_AUTHENTICATED');
    }

    final mockUser = _mockServerDb[_currentEmail!];
    if (mockUser == null) {
      throw const AuthException('User database error');
    }

    // Verify old password first
    final oldLmk = await _crypto.deriveLocalMasterKey(
      oldPassword,
      mockUser.salt,
    );
    final oldAuthToken = await _crypto.deriveAuthToken(oldLmk);
    if (oldAuthToken != mockUser.clientAuthToken) {
      throw const AuthException(
        'Invalid old password',
        code: 'INVALID_CREDENTIALS',
      );
    }

    final ak = _sessionKeys.currentAccountKey;
    if (ak == null) {
      throw const AuthException(
        'Encryption keys unavailable',
        code: 'KEYS_NOT_FOUND',
      );
    }

    // 1. Derive NEW LMK
    final newLmk = await _crypto.deriveLocalMasterKey(
      newPassword,
      mockUser.salt,
    );

    // 2. Derive NEW ClientAuthToken
    final newAuthToken = await _crypto.deriveAuthToken(newLmk);

    // 3. Re-wrap AK with NEW LMK
    final newWrappedAk = await _crypto.wrapKey(ak, newLmk);

    // 4. Update "Server"
    _mockServerDb[_currentEmail!] = _MockUserE2EE(
      salt: mockUser.salt,
      clientAuthToken: newAuthToken,
      wrappedAk: newWrappedAk,
      recoveryWrappedAk: mockUser.recoveryWrappedAk,
    );

    // 5. Update Session
    _sessionKeys.setMasterKey(newLmk);

    AppLogger.i('MockAuthRepository: Password changed successfully');
  }

  @override
  Future<void> recoverAccount({
    required String email,
    required String mnemonic,
    required String newPassword,
  }) async {
    AppLogger.i('MockAuthRepository: E2EE Account Recovery Attempt');
    await _initDefaults;
    await Future<void>.delayed(const Duration(seconds: 1));

    final mockUser = _mockServerDb[email];
    if (mockUser == null) {
      throw const AuthException('Account not found', code: 'ACCOUNT_NOT_FOUND');
    }

    // 1. Decode RK from mnemonic
    final rkBytes = _recovery.mnemonicToKey(mnemonic);
    final rk = SecretKey(rkBytes);
    final expandedRk = await _crypto.expandKey(rk);

    // 2. Unwrap AK using RK
    final ak = await _crypto.unwrapKey(mockUser.recoveryWrappedAk, expandedRk);

    // 3. Derive NEW LMK
    final newLmk = await _crypto.deriveLocalMasterKey(
      newPassword,
      mockUser.salt,
    );

    // 4. Derive NEW ClientAuthToken
    final newAuthToken = await _crypto.deriveAuthToken(newLmk);

    // 5. Re-wrap AK with NEW LMK
    final newWrappedAk = await _crypto.wrapKey(ak, newLmk);

    // 6. Update "Server"
    _mockServerDb[email] = _MockUserE2EE(
      salt: mockUser.salt,
      clientAuthToken: newAuthToken,
      wrappedAk: newWrappedAk,
      recoveryWrappedAk: mockUser.recoveryWrappedAk,
    );

    // 7. Auto-login (Establish Session)
    if (email == 'test@example.com') {
      _currentUser = 'mock-user-id';
    } else {
      _currentUser = 'mock-user-${email.hashCode}';
    }
    _currentEmail = email;
    _sessionKeys.setMasterKey(newLmk);
    _sessionKeys.setAccountKey(ak);

    await _storage.saveTokens(
      TokenPair(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    _controller.add(_currentUser);
    AppLogger.i('MockAuthRepository: Account recovery successful');
  }

  @override
  Future<void> loginAnonymously() async {
    AppLogger.i('MockAuthRepository: Anonymous login (No E2EE)');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = AppStrings.guestUserId;
    _currentEmail = null;
    _sessionKeys.clear(); // Guest mode has no E2EE keys in this phase
    _controller.add(_currentUser);
  }

  @override
  Future<void> logout() async {
    AppLogger.i('MockAuthRepository: Logging out');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _currentEmail = null;
    _sessionKeys.clear();
    await _storage.deleteTokens();
    _controller.add(_currentUser);
  }

  @override
  Future<void> finalizeRegistration() async {
    AppLogger.i('MockAuthRepository: Finalizing registration');
    _controller.add(_currentUser);
  }

  @override
  Future<void> deleteAccount() async {
    AppLogger.i('MockAuthRepository: Deleting account');
    if (_useDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    if (_currentEmail != null) {
      _mockServerDb.remove(_currentEmail);
    }
    _currentUser = null;
    _currentEmail = null;
    _sessionKeys.clear();
    await _storage.deleteTokens();
    _controller.add(_currentUser);
  }

  /// Sets the current user directly.
  void setUser(String? userId, [String? email]) {
    _currentUser = userId;
    _currentEmail = email;
    _controller.add(_currentUser);
  }

  /// Seeds a user into the mock server database.
  /// This is useful for testing login flows without registering first.
  Future<void> seedUser(String email, String password) async {
    final salt = List<int>.generate(16, (i) => i);
    final lmk = await _crypto.deriveLocalMasterKey(password, salt);
    final authToken = await _crypto.deriveAuthToken(lmk);
    final ak = await _crypto.generateRandomKey();
    final wrappedAk = await _crypto.wrapKey(ak, lmk);

    // Seed recovery key too
    final rkBytes = List<int>.generate(16, (i) => i + 10);
    final expandedRk = await _crypto.expandKey(SecretKey(rkBytes));
    final recoveryWrappedAk = await _crypto.wrapKey(ak, expandedRk);

    _mockServerDb[email] = _MockUserE2EE(
      salt: salt,
      clientAuthToken: authToken,
      wrappedAk: wrappedAk,
      recoveryWrappedAk: recoveryWrappedAk,
    );
  }

  void dispose() {
    _controller.close();
  }
}

class _MockUserE2EE {
  final List<int> salt;
  final String clientAuthToken;
  final String wrappedAk;
  final String recoveryWrappedAk;

  const _MockUserE2EE({
    required this.salt,
    required this.clientAuthToken,
    required this.wrappedAk,
    required this.recoveryWrappedAk,
  });
}
