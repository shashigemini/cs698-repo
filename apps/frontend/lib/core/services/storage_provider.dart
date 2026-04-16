import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'secure_storage_service.dart';
import 'storage_service.dart';

part 'storage_provider.g.dart';

/// Provides the active [StorageService] implementation.
///
/// Returns [SecureStorageService] by default for production use.
/// Can be overridden in tests or development environments
/// to provide a mock implementation.
@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) {
  return const SecureStorageService();
}
