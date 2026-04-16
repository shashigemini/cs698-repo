import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';

void main() {
  group('Auth Model Serialization', () {
    test('TokenPair serialization', () {
      final now = DateTime.now();
      final tokenPair = TokenPair(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiresAt: now,
      );

      final json = tokenPair.toJson();
      expect(json['access_token'], 'access');
      expect(json['refresh_token'], 'refresh');
      expect(json['access_expires_at'], now.toIso8601String());

      final fromJson = TokenPair.fromJson(json);
      expect(fromJson.accessToken, tokenPair.accessToken);
      expect(fromJson.refreshToken, tokenPair.refreshToken);
      expect(fromJson.accessExpiresAt, tokenPair.accessExpiresAt);
    });
  });
}
