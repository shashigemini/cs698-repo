import '../../../features/auth/domain/models/token_pair.dart';
import 'storage_service.dart';

/// In-memory implementation of [StorageService] for development.
///
/// Stores values in a plain [Map] — data is lost when the app
/// restarts. Suitable for widget tests and UI development.
class MockStorageService implements StorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> saveTokens(TokenPair tokenPair) async {
    _store['accessToken'] = tokenPair.accessToken;
    _store['refreshToken'] = tokenPair.refreshToken;
    _store['accessExpiresAt'] = tokenPair.accessExpiresAt.toIso8601String();
  }

  @override
  Future<TokenPair?> getTokens() async {
    final access = _store['accessToken'];
    final refresh = _store['refreshToken'];
    final expiresAt = _store['accessExpiresAt'];
    if (access == null || refresh == null || expiresAt == null) {
      return null;
    }
    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: DateTime.parse(expiresAt),
    );
  }

  @override
  Future<void> deleteTokens() async {
    _store.remove('accessToken');
    _store.remove('refreshToken');
    _store.remove('accessExpiresAt');
  }

  @override
  Future<void> saveGuestSessionId(String id) async {
    _store['guestSessionId'] = id;
  }

  @override
  Future<String?> getGuestSessionId() async {
    return _store['guestSessionId'];
  }

  @override
  Future<void> saveCsrfToken(String token) async {
    _store['csrfToken'] = token;
  }

  @override
  Future<String?> getCsrfToken() async {
    return _store['csrfToken'];
  }
}
