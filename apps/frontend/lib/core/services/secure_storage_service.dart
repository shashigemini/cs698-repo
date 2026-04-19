import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../features/auth/domain/models/token_pair.dart';
import 'storage_service.dart';

/// Production implementation of [StorageService] utilizing
/// `flutter_secure_storage` to encrypt data securely on the device
/// (Keychain for iOS, EncryptedSharedPreferences for Android).
class SecureStorageService implements StorageService {
  final FlutterSecureStorage _storage;

  /// Creates a [SecureStorageService].
  const SecureStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions.defaultOptions,
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  }) : _storage = storage;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyAccessExpiresAt = 'access_expires_at';
  static const _keyGuestSessionId = 'guest_session_id';
  static const _keyCsrfToken = 'csrf_token';
  static const _keyUserRole = 'user_role';
  static const _keyUserEmail = 'user_email';

  @override
  Future<void> saveTokens(TokenPair tokenPair) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: tokenPair.accessToken),
      _storage.write(key: _keyRefreshToken, value: tokenPair.refreshToken),
      _storage.write(
        key: _keyAccessExpiresAt,
        value: tokenPair.accessExpiresAt.toIso8601String(),
      ),
    ]);
  }

  @override
  Future<TokenPair?> getTokens() async {
    final access = await _storage.read(key: _keyAccessToken);
    final refresh = await _storage.read(key: _keyRefreshToken);
    final expiresAtStr = await _storage.read(key: _keyAccessExpiresAt);

    if (access == null || refresh == null || expiresAtStr == null) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return null;

    // Optional: if the token is already expired, we could return null here
    // But usually we return it so the repo can attempt a refresh.
    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: expiresAt,
    );
  }

  @override
  Future<void> deleteTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyAccessExpiresAt),
      _storage.delete(key: _keyUserRole),
      _storage.delete(key: _keyUserEmail),
    ]);
  }

  @override
  Future<void> saveGuestSessionId(String id) async {
    await _storage.write(key: _keyGuestSessionId, value: id);
  }

  @override
  Future<String?> getGuestSessionId() async {
    return _storage.read(key: _keyGuestSessionId);
  }

  @override
  Future<void> saveCsrfToken(String token) async {
    await _storage.write(key: _keyCsrfToken, value: token);
  }

  @override
  Future<String?> getCsrfToken() async {
    return _storage.read(key: _keyCsrfToken);
  }

  @override
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
  }

  @override
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  @override
  Future<String?> getUserEmail() async {
    return _storage.read(key: _keyUserEmail);
  }

  @override
  Future<String?> getUserRole() async {
    return _storage.read(key: _keyUserRole);
  }

  @override
  Future<void> deleteUserRole() async {
    await _storage.delete(key: _keyUserRole);
  }

  @override
  Future<void> deleteUserEmail() async {
    await _storage.delete(key: _keyUserEmail);
  }
}
