import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/constants/app_strings.dart';
import '../domain/models/message.dart';
import '../domain/models/conversation.dart';

part 'chat_state.freezed.dart';

/// Immutable state for the chat UI.
///
/// Tracks the current list of [messages], loading state, errors,
/// guest query budget, and the active [conversationId].
@freezed
abstract class ChatState with _$ChatState {
  /// Creates a [ChatState] with sensible defaults for an empty
  /// conversation.
  const factory ChatState({
    @Default([]) List<Message> messages,
    @Default(false) bool isLoading,
    String? error,
    String? conversationId,
    @Default(false) bool rateLimitExceeded,
    @Default(AppStrings.guestQueryLimit) int guestQueriesRemaining,
    @Default([]) List<Conversation> recentConversations,
    @Default(0) int queryUsage,
    @Default(AppStrings.totalUsageLimit) int totalUsageLimit,
  }) = _ChatState;
}
