import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/chat_repository.dart';
import 'api_chat_repository_provider.dart';

part 'chat_repository_provider.g.dart';

/// Provides the active [ChatRepository] implementation.
///
/// Currently returns the live [ApiChatRepository] via delegation.
@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return ref.watch(apiChatRepositoryProvider);
}
