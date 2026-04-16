import 'dart:typed_data';

/// Interface for administrative operations.
abstract interface class AdminRepository {
  /// Upload and ingest a PDF document.
  Future<void> ingestDocument({
    required Uint8List fileBytes,
    required String filename,
    required String title,
    required String logicalBookId,
    String? author,
    String? edition,
  });

  /// List all ingested documents with their status.
  Future<List<Map<String, dynamic>>> listDocuments();

  /// Delete a document by its ID.
  Future<void> deleteDocument(String documentId);
}
