import 'package:dio/dio.dart';
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

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    AppLogger.d(
      'HttpInterceptor: onRequest',
      error: {
        'method': options.method,
        'path': options.path,
        'headers': AppLogger.scrub(options.headers),
        if (options.data is Map<String, dynamic>)
          'data': AppLogger.scrub(options.data as Map<String, dynamic>),
      },
    );

    final tokens = await _storage.getTokens();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }

    final csrf = await _storage.getCsrfToken();
    if (csrf != null) {
      options.headers['X-CSRF-Token'] = csrf;
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      AppLogger.w(
        'HttpInterceptor: 401 response received, attempting token refresh',
      );
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        AppLogger.i(
          'HttpInterceptor: Token refreshed successfully, retrying original request',
        );
        // Retry original request with new token
        final tokens = await _storage.getTokens();
        if (tokens != null) {
          err.requestOptions.headers['Authorization'] =
              'Bearer ${tokens.accessToken}';
        }
        try {
          final response = await _dio.fetch<dynamic>(err.requestOptions);
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

    // Map known error codes
    final code = err.response?.data is Map
        ? (err.response?.data as Map)['code'] as String?
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
      return true;
    } catch (e) {
      AppLogger.e('HttpInterceptor: Refresh request failed', error: e);
      // On refresh failure, we clear tokens to force user back to login
      await _storage.deleteTokens();
      return false;
    }
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password';
      case 'EMAIL_ALREADY_EXISTS':
        return 'An account with this email already exists';
      case 'TOKEN_EXPIRED':
        return 'Session expired. Please sign in again';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Rate limit exceeded';
      default:
        return 'An unexpected error occurred';
    }
  }
}
