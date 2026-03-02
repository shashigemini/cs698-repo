import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/env.dart';
import '../services/storage_provider.dart';
import 'http_interceptor.dart';

part 'dio_provider.g.dart';

/// Provides a configured [Dio] instance for network requests.
///
/// This provider ensures that the network client is a singleton
/// tied to the Riverpod lifecycle, injected with the [StorageService]
/// and [HttpInterceptor] for automatic token management.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final storageService = ref.watch(storageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Attach the interceptor for auth tokens, rate limits, and CSRF.
  dio.interceptors.add(HttpInterceptor(storage: storageService, dio: dio));

  // Configure SSL Pinning if enabled
  if (Env.useSslPinning) {
    dio.interceptors.add(
      CertificatePinningInterceptor(
        allowedSHAFingerprints: [Env.sslCertFingerprint],
      ),
    );
  }

  return dio;
}
