import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/repositories/admin_repository.dart';

/// HTTP implementation of [AdminRepository] for the
/// FastAPI backend.
class ApiAdminRepository implements AdminRepository {
  final Dio _dio;

  ApiAdminRepository({required Dio dio}) : _dio = dio;

  @override
  Future<void> ingestDocument({
    required Uint8List fileBytes,
    required String filename,
    required String title,
    required String logicalBookId,
    String? author,
    String? edition,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: filename,
      ),
      'title': title,
      'logical_book_id': logicalBookId,
      if (author != null) 'author': author,
      if (edition != null) 'edition': edition,
    });

    await _dio.post<dynamic>(
      '/api/admin/documents/ingest',
      data: formData,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments() async {
    AppLogger.w('🔥 ApiAdminRepository: Starting listDocuments request to \${_dio.options.baseUrl}/api/admin/documents');
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/admin/documents',
      );
      AppLogger.w('🔥 ApiAdminRepository: Got response with status \${response.statusCode}');
      return (response.data ?? []).cast<Map<String, dynamic>>();
    } catch (e, stack) {
      AppLogger.w('🔥 ApiAdminRepository: Caught error: $e\\n$stack');
      rethrow;
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _dio.delete<dynamic>(
      '/api/admin/documents/$documentId',
    );
  }
}
