import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/app_logger.dart';

void main() {
  group('AppLogger.scrub', () {
    test('should redact sensitive keys at the top level', () {
      final data = {
        'email': 'test@example.com',
        'password': 'secret123',
        'access_token': 'abc-123',
      };

      final result = AppLogger.scrub(data);

      expect(result['email'], 'test@example.com');
      expect(result['password'], '[REDACTED]');
      expect(result['access_token'], '[REDACTED]');
    });

    test('should redact sensitive keys case-insensitively', () {
      final data = {'PASSWORD': 'secret123', 'Authorization': 'Bearer token'};

      final result = AppLogger.scrub(data);

      expect(result['PASSWORD'], '[REDACTED]');
      expect(result['Authorization'], '[REDACTED]');
    });

    test('should redact nested sensitive keys', () {
      final data = {
        'user': {
          'id': 1,
          'credentials': {'password': 'password123'},
        },
      };

      final result = AppLogger.scrub(data);

      expect(result['user']['id'], 1);
      expect(result['user']['credentials']['password'], '[REDACTED]');
    });

    test('should redact sensitive keys in lists of maps', () {
      final data = {
        'items': [
          {'type': 'public', 'value': 'info'},
          {'type': 'secret', 'password': 'hidden'},
        ],
      };

      final result = AppLogger.scrub(data);

      expect(result['items'][0]['value'], 'info');
      expect(result['items'][1]['password'], '[REDACTED]');
    });

    test('should handle mixed types and maintain non-sensitive data', () {
      final data = {
        'count': 5,
        'flag': true,
        'tags': ['a', 'b'],
        'apiKey': 'super-secret',
      };

      final result = AppLogger.scrub(data);

      expect(result['count'], 5);
      expect(result['flag'], true);
      expect(result['tags'], ['a', 'b']);
      expect(result['apiKey'], '[REDACTED]');
    });
  });
}
