import 'package:flutter/foundation.dart';

/// JWT token pair returned after successful authentication.
///
/// Contains both the short-lived [accessToken] for API calls
/// and the long-lived [refreshToken] for obtaining new access
/// tokens when the current one expires.
@immutable
class TokenPair {
  /// The short-lived JWT access token.
  final String accessToken;

  /// The long-lived JWT refresh token.
  final String refreshToken;

  /// When the [accessToken] expires.
  final DateTime accessExpiresAt;

  /// Creates a [TokenPair].
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
  });

  /// Whether the [accessToken] has expired.
  bool get isExpired => DateTime.now().isAfter(accessExpiresAt);

  /// Creates a [TokenPair] from a JSON map.
  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
    );
  }

  /// Converts this [TokenPair] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_expires_at': accessExpiresAt.toIso8601String(),
    };
  }
}
