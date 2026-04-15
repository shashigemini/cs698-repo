import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// The possible authentication statuses.
enum AuthStatus {
  /// App has not yet checked for stored tokens.
  initial,

  /// A login or register request is in progress.
  loading,

  /// The user is authenticated.
  authenticated,

  /// The user is not authenticated.
  unauthenticated,

  /// An authentication error occurred.
  error,
}

/// Immutable state for the authentication layer.
///
/// Tracks the current [status], the authenticated [user] email,
/// any [errorMessage] from failed operations, and a convenience
/// [isLoading] flag.
@freezed
abstract class AuthState with _$AuthState {
  /// Creates an [AuthState] with sensible defaults.
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    String? user,
    String? errorMessage,
    @Default(false) bool isLoading,
  }) = _AuthState;
}
