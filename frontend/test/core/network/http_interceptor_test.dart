import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/http_interceptor.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements StorageService {}

class MockDio extends Mock implements Dio {}

void main() {
  late HttpInterceptor interceptor;
  late MockStorage mockStorage;
  late MockDio mockDio;
  late MockDio mockRefreshDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(
      TokenPair(
        accessToken: '',
        refreshToken: '',
        accessExpiresAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '')),
    );
  });

  setUp(() {
    mockStorage = MockStorage();
    mockDio = MockDio();
    mockRefreshDio = MockDio();
    interceptor = HttpInterceptor(
      storage: mockStorage,
      dio: mockDio,
      refreshDio: mockRefreshDio,
    );

    // Default stubs
    when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
    when(() => mockStorage.getCsrfToken()).thenAnswer((_) async => null);
  });

  group('HttpInterceptor', () {
    test('onRequest attaches Authorization header when tokens exist', () async {
      final tokens = TokenPair(
        accessToken: 'valid-token',
        refreshToken: 'refresh-token',
        accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(() => mockStorage.getTokens()).thenAnswer((_) async => tokens);

      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer valid-token');
    });

    test('onRequest attaches CSRF header when token exists', () async {
      when(
        () => mockStorage.getCsrfToken(),
      ).thenAnswer((_) async => 'csrf-123');

      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['X-CSRF-Token'], 'csrf-123');
    });

    test('onError attempts refresh on 401', () async {
      final tokens = TokenPair(
        accessToken: 'expired-token',
        refreshToken: 'valid-refresh',
        accessExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      when(() => mockStorage.getTokens()).thenAnswer((_) async => tokens);

      // Stub the refresh request on the mockRefreshDio
      when(
        () => mockRefreshDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/refresh'),
          statusCode: 200,
          data: {
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
            'access_expires_at': DateTime.now()
                .add(const Duration(hours: 1))
                .toIso8601String(),
          },
        ),
      );

      when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});

      // Stub the retry request on mockDio
      when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );
      final handler = ErrorInterceptorHandler();

      await interceptor.onError(err, handler);

      verify(() => mockDio.fetch<dynamic>(any())).called(1);
    });

    test('onError maps error codes to AppNetworkException', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'code': 'INVALID_CREDENTIALS'},
        ),
      );
      final handler = MockErrorInterceptorHandler();

      await interceptor.onError(err, handler);

      verify(() => handler.reject(any())).called(1);
    });
  });
}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}
