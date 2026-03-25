import 'package:dio/dio.dart';

class ApiAuthRepository {
  final Dio _dio;

  ApiAuthRepository(this._dio);

  Future<String> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data['token'];
  }
}
