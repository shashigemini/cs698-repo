import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

class HttpInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('--- HTTP Request ---');
    AppLogger.d('URI: \${options.uri}');
    AppLogger.d('Method: \${options.method}');
    AppLogger.d('Headers: \${options.headers}');
    AppLogger.d('Data: \${options.data}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('--- HTTP Response ---');
    AppLogger.d('Status: \${response.statusCode}');
    AppLogger.d('Data: \${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e('--- HTTP Error ---');
    AppLogger.e('Type: \${err.type}');
    AppLogger.e('Message: \${err.message}');
    AppLogger.e('Response: \${err.response}');
    return super.onError(err, handler);
  }
}
