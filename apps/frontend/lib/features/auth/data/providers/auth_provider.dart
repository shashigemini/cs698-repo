import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/storage_provider.dart';
import '../../../../core/services/cryptography_provider.dart';
import '../../../../core/services/session_key_store.dart';
import '../../../../core/services/recovery_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../repositories/api_auth_repository.dart';

part 'auth_provider.g.dart';

/// Currently returns [ApiAuthRepository].
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  final storageService = ref.watch(storageServiceProvider);
  final cryptoService = ref.watch(cryptographyServiceProvider);
  final sessionKeys = ref.watch(sessionKeyStoreProvider.notifier);
  final recoveryService = ref.watch(recoveryServiceProvider);

  return ApiAuthRepository(
    dio: dio,
    storage: storageService,
    crypto: cryptoService,
    sessionKeys: sessionKeys,
    recovery: recoveryService,
  );
}
