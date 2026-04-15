import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:cryptography/cryptography.dart';
import 'package:frontend/core/services/cryptography_provider.dart';
import 'package:frontend/core/services/cryptography_service.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:frontend/core/services/recovery_provider.dart';
import 'package:frontend/core/services/session_key_store.dart';
import 'package:frontend/core/services/storage_provider.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/api_auth_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/data/repositories/api_chat_repository.dart';
import 'package:frontend/core/services/mock_storage_service.dart';
import 'package:frontend/core/network/http_interceptor.dart';
import 'package:frontend/main.dart'; 

class E2ETestUtils {
  static final String baseUrl = Platform.environment['E2E_BASE_URL'] ?? 'http://localhost:8000';
  
  static final MockStorageService _storage = MockStorageService();
  
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    dio.interceptors.add(HttpInterceptor(storage: _storage, dio: dio));
    return dio;
  }

  static Future<void> buildE2ETestApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _storage.clear();

    await waitForBackend();
    
    final fakeCrypto = _FakeCryptographyService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageServiceProvider.overrideWithValue(_storage),
          cryptographyServiceProvider.overrideWithValue(fakeCrypto),
          authRepositoryProvider.overrideWith((ref) {
            final storageService = ref.watch(storageServiceProvider);
            final cryptoService = ref.watch(cryptographyServiceProvider);
            final sessionKeys = ref.watch(sessionKeyStoreProvider.notifier);
            final recoveryService = ref.watch(recoveryServiceProvider);
            
            return ApiAuthRepository(
              dio: _dio,
              crypto: cryptoService,
              sessionKeys: sessionKeys,
              storage: storageService,
              recovery: recoveryService,
            );
          }),
          chatRepositoryProvider.overrideWith((ref) {
            return ApiChatRepository(dio: _dio);
          }),
        ],
        child: const SpiritualQaApp(disableSecurity: true),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  static Future<void> waitForBackend() async {
    debugPrint('⏳ Waiting for backend to be ready...');
    var attempts = 0;
    const maxAttempts = 30; // 30 seconds total
    while (attempts < maxAttempts) {
      try {
        final res = await _dio.get<dynamic>('/api/test/ready');
        if (res.statusCode == 200) {
          debugPrint('✅ Backend is ready!');
          return;
        }
      } catch (e) {
        debugPrint('... attempt ${attempts + 1} failed, retrying');
      }
      attempts++;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw Exception('❌ Backend not ready after $maxAttempts seconds');
  }

  static Future<void> resetBackendState() async {
    await _dio.post<dynamic>('/api/test/reset');
  }

  static Future<void> seedAllData() async {
    await _dio.post<dynamic>('/api/test/seed');
  }

  static Future<void> seedTestUser(String email, String password) async {
    await _dio.post<dynamic>(
      '/api/test/seed-user',
      data: {'email': email, 'password': password},
    );
  }
}

class _FakeCryptographyService extends CryptographyService {
  @override
  Future<SecretKey> deriveLocalMasterKey(String password, List<int> salt) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      info: salt,
    );
  }

  @override
  Future<SecretKey> unwrapKey(
    String wrappedKeyBase64,
    SecretKey wrappingKey, {
    List<int>? aad,
  }) async {
    // Backend seeds 'dGVzdA==' (base64 for 'test') as a dummy AK.
    // If it doesn't look like a real AES-GCM box, return a dummy key.
    if (!wrappedKeyBase64.contains('.')) {
      return SecretKey(utf8.encode('dummy-test-key-32-chars-long-!!!'));
    }
    return super.unwrapKey(wrappedKeyBase64, wrappingKey, aad: aad);
  }
}
