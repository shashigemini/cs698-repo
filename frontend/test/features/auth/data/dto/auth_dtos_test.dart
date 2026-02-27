import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/dto/auth_dtos.dart';

void main() {
  group('Auth DTOs', () {
    test('LoginRequestDto serialization', () {
      const dto = LoginRequestDto(
        email: 'test@example.com',
        password: 'password123',
      );

      final json = dto.toJson();
      expect(json['email'], 'test@example.com');
      expect(json['password'], 'password123');

      final fromJson = LoginRequestDto.fromJson(json);
      expect(fromJson, dto);
    });

    test('TokenResponseDto serialization', () {
      final json = {
        'access_token': 'access',
        'refresh_token': 'refresh',
        'access_expires_at': '2023-10-27T10:00:00Z',
      };

      final dto = TokenResponseDto.fromJson(json);
      expect(dto.accessToken, 'access');
      expect(dto.refreshToken, 'refresh');
      expect(dto.accessExpiresAt, '2023-10-27T10:00:00Z');

      expect(dto.toJson(), json);
    });
  });
}
