import 'package:dio/dio.dart';

class ApiChatRepository {
  final Dio _dio;

  ApiChatRepository(this._dio);

  Future<String> sendMessage(String message) async {
    final response = await _dio.post('/chat', data: {'message': message});
    return response.data['response'];
  }
}
