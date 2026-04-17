/// Contract for authentication operations.
///
/// Implementations handle user registration, login, anonymous
/// guest access, and logout. The [authStateChanges] stream
/// notifies listeners of authentication state transitions.
abstract class AuthRepository {
  /// Restores any persisted session state (if present) during app startup.
  ///
  /// This method should be awaited before routing decisions depend on auth.
  Future<void> initializeSession();

  /// Authenticates a user with [email] and [password].
  ///
  /// Throws an [Exception] if credentials are invalid.
  Future<void> login(String email, String password);

  /// Registers a new user and returns a recovery mnemonic phrase.
  Future<String> register(String email, String password);

  /// Signs in anonymously as a guest user.
  ///
  /// Guest users are rate-limited and their conversations are
  /// not persisted.
  Future<void> loginAnonymously();

  /// Standard logout.
  Future<void> logout();

  /// Changes the user's password, re-wrapping the AccountKey using [oldPassword].
  Future<void> changePassword(String oldPassword, String newPassword);

  /// Recovers an account using a recovery phrase and sets a new password.
  Future<void> recoverAccount({
    required String email,
    required String mnemonic,
    required String newPassword,
  });

  /// Stream that emits the current user ID (or `null`) whenever
  /// the authentication state changes.
  Stream<String?> get authStateChanges;

  /// The current user's ID, or `null` if not authenticated.
  String? get currentUserId;

  /// Finalizes the registration process, transitioning from "registered"
  /// to "authenticated" state. This should be called after the user
  /// has acknowledged their recovery mnemonic.
  Future<void> finalizeRegistration();

  /// Deletes the current user's account permanently.
  Future<void> deleteAccount();
}
