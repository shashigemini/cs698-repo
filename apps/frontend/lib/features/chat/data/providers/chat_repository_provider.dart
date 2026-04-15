import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/cryptography_provider.dart';
import '../../../../core/services/session_key_store.dart';
import '../../domain/repositories/chat_repository.dart';
import '../repositories/mock_chat_repository.dart' hide ChatRepository;

part 'chat_repository_provider.g.dart';

/// Provides the active [ChatRepository] implementation.
///
/// Currently returns [MockChatRepository]; swap for a real
/// implementation when the backend is available.
@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  // Establishing the dependency graph. A real implementation would accept Dio:
  final crypto = ref.watch(cryptographyServiceProvider);
  final sessionKeys = ref.watch(sessionKeyStoreProvider.notifier);
  return MockChatRepository(crypto: crypto, sessionKeys: sessionKeys);
}
