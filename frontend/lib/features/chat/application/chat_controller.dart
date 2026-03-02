import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/guest_service.dart';
import '../../auth/application/auth_controller.dart';
import '../data/providers/chat_repository_provider.dart';
import '../domain/models/message.dart';
import 'chat_state.dart';

part 'chat_controller.g.dart';

@Riverpod(keepAlive: true)
class ChatController extends _$ChatController {
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  bool _initialized = false;

  @override
  ChatState build() {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous != next) {
        state = const ChatState(); // Reset chat state
        _init(); // Reinitialize with new auth context
      }
    });

    if (!_initialized) {
      _initialized = true;
      _init();
    }
    return const ChatState();
  }

  Future<void> _init() async {
    try {
      final guestService = ref.read(guestServiceProvider);
      final repo = ref.read(chatRepositoryProvider);
      final conversations = await repo.getConversations();

      if (ref.mounted) {
        state = ChatState(
          guestQueriesRemaining: guestService.getQueriesRemaining(),
          recentConversations: conversations,
          queryUsage: conversations.length,
        );
      }
    } catch (e) {
      AppLogger.e('ChatController: Initialization failed', error: e);
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<void> sendQuery(String query, {String? guestSessionId}) async {
    final currentState = state;
    if (currentState.isLoading || currentState.rateLimitExceeded) return;

    if (guestSessionId != null && currentState.guestQueriesRemaining <= 0) {
      state = currentState.copyWith(
        rateLimitExceeded: true,
        error: 'Rate limit exceeded',
        guestQueriesRemaining: 0,
      );
      return;
    }

    final userMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      content: query,
      timestamp: DateTime.now(),
    );

    state = currentState.copyWith(
      messages: [...currentState.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.sendQuery(
        query,
        conversationId: currentState.conversationId,
        guestSessionId: guestSessionId,
      );

      final assistantMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'assistant',
        content: result.answer,
        citations: result.citations,
        timestamp: DateTime.now(),
      );

      if (!ref.mounted) return;

      final guestService = ref.read(guestServiceProvider);
      if (guestSessionId != null) {
        await guestService.incrementUsage();
      }

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        conversationId: result.conversationId,
        isLoading: false,
        guestQueriesRemaining: guestService.getQueriesRemaining(),
      );
    } catch (e, st) {
      if (!ref.mounted) return;
      final updatedState = state;
      AppLogger.e('ChatController error', error: e, stackTrace: st);
      if (e.toString().contains('RateLimitException')) {
        state = updatedState.copyWith(
          isLoading: false,
          rateLimitExceeded: true,
          error: 'Rate limit exceeded',
          guestQueriesRemaining: 0,
        );
      } else {
        state = updatedState.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> loadConversation(String id) async {
    final currentState = state;
    state = currentState.copyWith(
      isLoading: true,
      messages: [],
      conversationId: id,
    );
    try {
      final repo = ref.read(chatRepositoryProvider);
      final history = await repo.loadHistory(id);
      if (!ref.mounted) return;
      state = state.copyWith(messages: history, isLoading: false);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversation history',
      );
    }
  }

  Future<void> fetchRecentConversations() async {
    if (!ref.mounted) return;
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversations = await repo.getConversations();
      if (!ref.mounted) return;
      state = state.copyWith(
        recentConversations: conversations,
        queryUsage: conversations.length,
      );
    } catch (e) {
      AppLogger.e('ChatController: Failed to fetch conversations', error: e);
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.deleteConversation(id);
      await fetchRecentConversations();
      if (ref.mounted && state.conversationId == id) {
        newConversation();
      }
    } catch (e) {
      AppLogger.e('ChatController: Failed to delete conversation', error: e);
    }
  }

  Future<String?> exportConversation(String id) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      return await repo.exportConversation(id);
    } catch (e) {
      AppLogger.e('ChatController: Failed to export conversation', error: e);
      return null;
    }
  }

  void newConversation() {
    state = state.copyWith(
      messages: [],
      conversationId: null,
      error: null,
      rateLimitExceeded: false,
    );
  }

  void resetError() {
    state = state.copyWith(error: null);
  }
}
