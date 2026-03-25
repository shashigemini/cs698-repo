import 'dart:io';
import 'package:dio/dio.dart';

class ApiAdminRepository {
  final Dio _dio;

  ApiAdminRepository(this._dio);

  Future<void> uploadPdf(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    await _dio.post('/admin/upload-pdf', data: formData);
  }

  Future<List<String>> getStats() async {
    final response = await _dio.get('/admin/stats');
    return List<String>.from(response.data['stats']);
  }
}
