/// Base class for all application-specific exceptions.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Exception thrown for network-related errors.
class AppNetworkException extends AppException {
  const AppNetworkException(super.message, {super.code});
}

/// Exception thrown specifically for authentication failures.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}
