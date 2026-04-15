import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/providers/auth_provider.dart';

part 'auth_controller.g.dart';

/// Indicates whether the initial auth token check has completed.
/// This prevents the [GoRouter] from prematurely redirecting to `/login`
/// while tokens are still being loaded from secure storage.
@Riverpod(keepAlive: true)
class AuthInitialization extends _$AuthInitialization {
  @override
  bool build() => false;

  void complete() {
    state = true;
  }
}

/// Manages the authentication state of the application.
///
/// Converts the stream of auth state changes from the repository into
/// Riverpod state, and exposes authentication actions to the UI.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  String? build() {
    final repo = ref.watch(authRepositoryProvider);

    // Listen to repo for future updates
    final sub = repo.authStateChanges.listen((user) {
      state = user;
      final initNotifier = ref.read(authInitializationProvider.notifier);
      if (!ref.read(authInitializationProvider)) {
        initNotifier.complete();
      }
    });

    ref.onDispose(() {
      sub.cancel();
    });

    // Mark initialization as complete immediately since initial state
    // is known synchronously from the repository upon instantiation.
    Future.microtask(() {
      if (!ref.read(authInitializationProvider)) {
        ref.read(authInitializationProvider.notifier).complete();
      }
    });

    // Return the synchronous current state immediately
    return repo.currentUserId;
  }

  /// The current user ID.
  String? get currentUserId => state;

  /// Registers a new user.
  ///
  /// Returns the recovery mnemonic phrase.
  Future<String> register(String email, String password) async {
    return await _authRepository.register(email, password);
  }

  /// Finalizes the registration process.
  Future<void> finalizeRegistration() async {
    await _authRepository.finalizeRegistration();
  }

  /// Logs in a user.
  Future<void> login(String email, String password) async {
    // Repository throws on failure, which bubbles to UI snackbar
    await _authRepository.login(email, password);
  }

  /// Logs in anonymously.
  Future<void> loginAnonymously() async {
    await _authRepository.loginAnonymously();
  }

  /// Changes the user's password.
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(oldPassword, newPassword);
      return true;
    } catch (e) {
      AppLogger.e('Change password error: $e');
      return false;
    }
  }

  /// Recovers an account.
  Future<bool> recoverAccount({
    required String email,
    required String mnemonic,
    required String newPassword,
  }) async {
    try {
      await _authRepository.recoverAccount(
        email: email,
        mnemonic: mnemonic,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      AppLogger.e('Recover account error: $e');
      return false;
    }
  }

  /// Logs out the user.
  Future<void> logout() async {
    await _authRepository.logout();
  }

  /// Deletes the current user's account permanently.
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
  }
}
