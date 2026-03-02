import '../models/answer_result.dart';
import '../models/message.dart';
import '../models/conversation.dart';

/// Contract for accessing the chat / RAG API.
///
/// Implementations handle sending user queries and retrieving
/// conversation history. See [MockChatRepository] for the
/// development stub.
abstract class ChatRepository {
  /// Sends a [query] to the RAG system.
  ///
  /// Pass [conversationId] to continue an existing conversation
  /// (authenticated users) or [guestSessionId] for guest mode.
  ///
  /// Returns an [AnswerResult] with the AI answer and citations.
  ///
  /// Throws an [Exception] on rate-limit violations or network
  /// errors.
  Future<AnswerResult> sendQuery(
    String query, {
    String? conversationId,
    String? guestSessionId,
  });

  /// Loads the message history for [conversationId].
  ///
  /// Returns messages in chronological order. Only available
  /// for authenticated users.
  Future<List<Message>> loadHistory(String conversationId);

  /// Returns a list of all past conversations for the authenticated user.
  Future<List<Conversation>> getConversations();

  /// Deletes a specific conversation by ID.
  Future<void> deleteConversation(String id);

  /// Exports a conversation as a JSON/Markdown string.
  Future<String> exportConversation(String id);
}
