import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/storage_provider.dart';
import '../../../../core/services/cryptography_provider.dart';
import '../../../../core/services/session_key_store.dart';
import '../../../../core/services/recovery_provider.dart';
import '../repositories/mock_auth_repository.dart';

part 'auth_provider.g.dart';

/// Provides the active [AuthRepository] implementation.
///
/// Currently returns [MockAuthRepository]; swap for a real
/// implementation when the backend is available.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final storageService = ref.watch(storageServiceProvider);
  final cryptoService = ref.watch(cryptographyServiceProvider);
  final sessionKeys = ref.watch(sessionKeyStoreProvider.notifier);
  final recoveryService = ref.watch(recoveryServiceProvider);

  return MockAuthRepository(
    storage: storageService,
    crypto: cryptoService,
    sessionKeys: sessionKeys,
    recovery: recoveryService,
  );
}
