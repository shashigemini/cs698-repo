import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import '../services/storage_service.dart';
import '../exceptions/app_exceptions.dart';
import '../../../features/auth/domain/models/token_pair.dart';
import '../utils/app_logger.dart';

/// Dio interceptor for authentication and error handling.
///
/// Automatically attaches the access token and CSRF token to
/// outgoing requests, attempts token refresh on 401 responses,
/// and maps server error codes to typed exceptions.
class HttpInterceptor extends Interceptor {
  static const String _refreshRetriedKey = 'refresh_retried';

  final StorageService _storage;
  final Dio _dio;
  final Dio? _refreshDio;

  /// Creates an [HttpInterceptor].
  ///
  /// [storage] provides token persistence.
  /// [dio] is the underlying client used for requests.
  /// [refreshDio] is an optional standalone client used for token refresh
  /// to avoid infinite loops. If null, a new instance is created on demand.
  HttpInterceptor({
    required StorageService storage,
    required Dio dio,
    Dio? refreshDio,
  }) : _storage = storage,
       _dio = dio,
       _refreshDio = refreshDio;

  bool _isBootstrapAuthPath(String path) {
    final normalizedPath = Uri.tryParse(path)?.path ?? path;
    const bootstrapPaths = <String>{
      '/api/auth/login',
      '/api/auth/login/verify',
      '/api/auth/register',
      '/api/auth/recover',
      '/api/auth/refresh',
    };
    return bootstrapPaths.contains(normalizedPath);
  }

  bool _shouldSkipRefreshPath(String path) {
    final normalizedPath = Uri.tryParse(path)?.path ?? path;
    return _isBootstrapAuthPath(normalizedPath) || normalizedPath == '/api/csrf';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    AppLogger.w('🔥 HttpInterceptor: onRequest ${options.method} ${options.path}');

    if (_isBootstrapAuthPath(options.path)) {
      handler.next(options);
      return;
    }

    TokenPair? tokens;
    try {
      AppLogger.w('🔥 HttpInterceptor: Calling _storage.getTokens()');
      tokens = await _storage.getTokens();
      AppLogger.w('🔥 HttpInterceptor: Finished _storage.getTokens()');
    } catch (e, stackTrace) {
      AppLogger.w(
        'HttpInterceptor: Failed to read auth tokens from storage; proceeding without auth headers',
        error: e,
        stackTrace: stackTrace,
      );
      handler.next(options);
      return;
    }

    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }

    try {
      final csrf = await _storage.getCsrfToken();
      if (csrf != null) {
        options.headers['X-CSRF-Token'] = csrf;
      }
    } catch (e, stackTrace) {
      AppLogger.w(
        'HttpInterceptor: Failed to read CSRF token from storage; proceeding without CSRF header',
        error: e,
        stackTrace: stackTrace,
      );
    }

    AppLogger.w('🔥 HttpInterceptor: Calling handler.next()');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint('HttpInterceptor: onResponse ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    debugPrint('HttpInterceptor: onError ${err.type} ${err.response?.statusCode} ${err.requestOptions.path}');
    debugPrint('HttpInterceptor: error data: ${err.response?.data}');
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final alreadyRetried = err.requestOptions.extra[_refreshRetriedKey] == true;
      if (alreadyRetried) {
        AppLogger.d('HttpInterceptor: Skipping refresh, request already retried: $path');
      } else if (_shouldSkipRefreshPath(path)) {
        AppLogger.d('HttpInterceptor: Skipping refresh for endpoint: $path');
      } else {
        AppLogger.w(
          'HttpInterceptor: 401 response received, attempting token refresh',
        );
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          AppLogger.i(
            'HttpInterceptor: Token refreshed successfully, retrying original request',
          );
          // Retry original request with new token and refreshed CSRF token
          final tokens = await _storage.getTokens();
          final retryOptions = err.requestOptions.copyWith(
            headers: Map<String, dynamic>.from(err.requestOptions.headers),
            extra: Map<String, dynamic>.from(err.requestOptions.extra)
              ..[_refreshRetriedKey] = true,
          );
          if (tokens != null) {
            retryOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          final freshCsrf = await _storage.getCsrfToken();
          if (freshCsrf != null) {
            retryOptions.headers['X-CSRF-Token'] = freshCsrf;
          }
          try {
            final response = await _dio.fetch<dynamic>(retryOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            AppLogger.e(
              'HttpInterceptor: Retry request failed after token refresh',
              error: e,
            );
            // Fall through to default error handling
          }
        } else {
          AppLogger.w('HttpInterceptor: Token refresh failed');
        }
      }
    }

    // Map known error codes
    final code = err.response?.data is Map
        ? ((err.response?.data as Map)['error_code'] as String? ??
            (err.response?.data as Map)['code'] as String?)
        : null;
    if (code != null) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AppNetworkException(_mapErrorCode(code), code: code),
          type: err.type,
          response: err.response,
        ),
      );
      return;
    }

    handler.next(err);
  }

  Future<bool> _attemptTokenRefresh() async {
    final tokens = await _storage.getTokens();
    if (tokens == null) return false;

    // Use the provided refresh client or a standalone instance
    final refreshDio =
        _refreshDio ??
        Dio(
          BaseOptions(
            baseUrl: _dio.options.baseUrl,
            connectTimeout: _dio.options.connectTimeout,
            receiveTimeout: _dio.options.receiveTimeout,
          ),
        );

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
      );

      final data = response.data;
      if (data == null) return false;

      final newTokenPair = TokenPair.fromJson(data);
      await _storage.saveTokens(newTokenPair);

      // Keep the stored role in sync with the new JWT so that the next
      // session restore reads the correct role (not a stale cached value).
      final newRole = _extractRoleFromJwt(newTokenPair.accessToken);
      await _storage.saveUserRole(newRole);

      // CSRF tokens are keyed to sha256(access_token) on the backend.
      // After token rotation the old CSRF token is invalid — fetch a new one.
      try {
        final csrfResponse = await refreshDio.get<Map<String, dynamic>>(
          '/api/csrf',
          options: Options(
            headers: {'Authorization': 'Bearer ${newTokenPair.accessToken}'},
          ),
        );
        final csrfToken = csrfResponse.data?['csrf_token'] as String?;
        if (csrfToken != null) {
          await _storage.saveCsrfToken(csrfToken);
        }
      } catch (_) {
        // Non-fatal: CSRF not enforced in dev/staging environments
      }

      return true;
    } catch (e) {
      AppLogger.e('HttpInterceptor: Refresh request failed', error: e);
      // On refresh failure, we clear tokens to force user back to login
      await _storage.deleteTokens();
      return false;
    }
  }

  String _extractRoleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'user';
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return claims['role'] as String? ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return AppStrings.invalidCredentials;
      case 'EMAIL_ALREADY_EXISTS':
        return 'An account with this email already exists';
      case 'TOKEN_EXPIRED':
        return 'Session expired. Please sign in again';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Rate limit exceeded';
      case 'LLM_ERROR':
        return 'AI service temporarily unavailable';
      case 'RETRIEVAL_ERROR':
        return 'Document retrieval service temporarily unavailable';
      default:
        return 'An unexpected error occurred';
    }
  }
}
