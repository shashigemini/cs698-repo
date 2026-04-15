import '../../../features/auth/domain/models/token_pair.dart';

/// Platform abstraction for secure token and session storage.
///
/// Implementations provide secure storage for authentication
/// tokens, guest session identifiers, and CSRF tokens.
/// See [MockStorageService] for the development stub.
abstract class StorageService {
  /// Persists [tokenPair] securely.
  Future<void> saveTokens(TokenPair tokenPair);

  /// Retrieves the stored [TokenPair], or `null` if none exists.
  Future<TokenPair?> getTokens();

  /// Removes stored tokens (e.g. on logout).
  Future<void> deleteTokens();

  /// Stores the guest session identifier.
  Future<void> saveGuestSessionId(String id);

  /// Retrieves the stored guest session identifier.
  Future<String?> getGuestSessionId();

  /// Stores the CSRF token from the server.
  Future<void> saveCsrfToken(String token);

  /// Retrieves the stored CSRF token.
  Future<String?> getCsrfToken();
}
