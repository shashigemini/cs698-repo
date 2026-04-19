import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/auth/data/providers/auth_provider.dart';
import '../data/providers/admin_repository_provider.dart';

part 'admin_controller.g.dart';

/// Provides whether the current authenticated user has admin privileges.
/// Role is extracted from the JWT access token at login time and persisted.
@riverpod
bool isAdmin(Ref ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentRole == 'admin';
}

@Riverpod(keepAlive: true)
class AdminController extends _$AdminController {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Upload and ingest a PDF document.
  Future<bool> ingestDocument({
    required Uint8List fileBytes,
    required String filename,
    required String title,
    required String logicalBookId,
    String? author,
    String? edition,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).ingestDocument(
            fileBytes: fileBytes,
            filename: filename,
            title: title,
            logicalBookId: logicalBookId,
            author: author,
            edition: edition,
          ),
    );
    return !state.hasError;
  }

  /// Fetch the list of all ingested documents.
  Future<List<Map<String, dynamic>>> listDocuments() async {
    final result = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).listDocuments(),
    );
    if (result.hasError) {
      // ignore: avoid_print
      print('🔥 listDocuments ERROR: ${result.error} \n ${result.stackTrace}');
    }
    return result.value ?? [];
  }

  /// Delete a document by ID.
  Future<bool> deleteDocument(String documentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).deleteDocument(documentId),
    );
    return !state.hasError;
  }
}
