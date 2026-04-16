import 'package:dio/dio.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/models/answer_result.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Real HTTP implementation of [ChatRepository] that interacts with the backend.
class ApiChatRepository implements ChatRepository {
  final Dio _dio;

  ApiChatRepository({required Dio dio}) : _dio = dio;

  @override
  Future<AnswerResult> sendQuery(
    String query, {
    String? conversationId,
    String? guestSessionId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/chat/query',
        data: {
          'query': query,
          if (conversationId != null) 'conversation_id': conversationId,
          if (guestSessionId != null) 'guest_session_id': guestSessionId,
        },
      );
      return AnswerResult.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  Future<List<Message>> loadHistory(String conversationId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/chat/conversations/$conversationId',
      );
      return response.data!
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/chat/conversations');
      return response.data!
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      await _dio.delete<void>('/api/chat/conversations/$id');
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  @override
  Future<String> exportConversation(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/chat/conversations/$id/export',
      );
      return response.data!['export_data'] as String;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(DioException e) {
    // If HttpInterceptor already mapped this to an AppException, use that!
    if (e.error is AppException) {
      throw Exception('API Error: ${(e.error as AppException).message}');
    }

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        final detail = data['detail'];
        throw Exception('API Error: $detail');
      }
    }
    throw Exception('API Error: ${e.message ?? 'Unknown error'}');
  }
}
