import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/repositories/chat_repository.dart';
import '../repositories/api_chat_repository.dart';

part 'api_chat_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ChatRepository apiChatRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ApiChatRepository(dio: dio);
}
