import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/session_key_store.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/features/auth/data/repositories/api_auth_repository.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/crypto_mocks.dart';

class MockDio extends Mock implements Dio {}

class MockStorage extends Mock implements StorageService {}

class MockSessionKeyStore extends Mock implements SessionKeyStore {}

class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TokenPair(
        accessToken: '',
        refreshToken: '',
        accessExpiresAt: DateTime.now(),
      ),
    );
    registerFallbackValue(FakeOptions());
    registerFallbackValue(SecretKey(const <int>[]));
  });

  group('ApiAuthRepository', () {
    late MockDio dio;
    late MockStorage storage;
    late FakeRecoveryService recovery;
    late MockSessionKeyStore sessionKeys;
    late FakeCryptographyService crypto;

    setUp(() {
      dio = MockDio();
      storage = MockStorage();
      recovery = FakeRecoveryService();
      sessionKeys = MockSessionKeyStore();
      crypto = FakeCryptographyService();

      when(() => storage.getTokens()).thenAnswer((_) async => null);
      when(() => storage.getUserRole()).thenAnswer((_) async => null);
      when(() => storage.saveTokens(any())).thenAnswer((_) async {});
      when(() => storage.saveCsrfToken(any())).thenAnswer((_) async {});
      when(() => storage.saveUserRole(any())).thenAnswer((_) async {});
      when(() => storage.saveUserEmail(any())).thenAnswer((_) async {});
      when(() => storage.getUserEmail()).thenAnswer((_) async => null);
      when(() => storage.deleteUserEmail()).thenAnswer((_) async {});
      when(() => sessionKeys.setMasterKey(any())).thenReturn(null);
      when(() => sessionKeys.setAccountKey(any())).thenReturn(null);

      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          data: <String, dynamic>{
            'salt': base64Url.encode(List<int>.filled(16, 7)),
          },
        ),
      );

      const payload = 'eyJyb2xlIjoidXNlciJ9';
      const accessToken = 'header.$payload.signature';

      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/login/verify',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/auth/login/verify'),
          data: <String, dynamic>{
            'access_token': accessToken,
            'refresh_token': 'refresh-token',
            'access_expires_at': DateTime.utc(2030, 1, 1).toIso8601String(),
            'wrapped_account_key':
                'wrapped-${base64.encode(List<int>.filled(32, 0))}',
          },
        ),
      );

      when(
        () => dio.get<Map<String, dynamic>>(
          '/api/csrf',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/csrf'),
          data: <String, dynamic>{'csrf_token': 'csrf-token'},
        ),
      );

      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/auth/register',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/auth/register'),
          data: <String, dynamic>{
            'access_token': accessToken,
            'refresh_token': 'refresh-token',
            'access_expires_at': DateTime.utc(2030, 1, 1).toIso8601String(),
          },
        ),
      );
    });

    test('login uses email as currentUserId', () async {
      final repository = ApiAuthRepository(
        dio: dio,
        crypto: crypto,
        sessionKeys: sessionKeys,
        storage: storage,
        recovery: recovery,
      );

      await repository.login('alice@example.com', 'Password123!');

      expect(repository.currentUserId, 'alice@example.com');
      verify(() => storage.saveUserEmail('alice@example.com')).called(1);
    });

    test('register uses email as currentUserId', () async {
      final repository = ApiAuthRepository(
        dio: dio,
        crypto: crypto,
        sessionKeys: sessionKeys,
        storage: storage,
        recovery: recovery,
      );

      await repository.register('new@example.com', 'Password123!');

      expect(repository.currentUserId, 'new@example.com');
      verify(() => storage.saveUserEmail('new@example.com')).called(1);
    });

    test('restore session uses persisted email for currentUserId', () async {
      final payload = base64Url.encode(
        utf8.encode('{"role":"user","email":"restored@example.com"}'),
      );
      when(() => storage.getTokens()).thenAnswer(
        (_) async => TokenPair(
          accessToken: 'header.$payload.signature',
          refreshToken: 'refresh-token',
          accessExpiresAt: DateTime.utc(2030, 1, 1),
        ),
      );
      when(
        () => storage.getUserEmail(),
      ).thenAnswer((_) async => 'restored@example.com');

      final repository = ApiAuthRepository(
        dio: dio,
        crypto: crypto,
        sessionKeys: sessionKeys,
        storage: storage,
        recovery: recovery,
      );

      await Future<void>.delayed(Duration.zero);

      expect(repository.currentUserId, 'restored@example.com');
    });
  });
}
