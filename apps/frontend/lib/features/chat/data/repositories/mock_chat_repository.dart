import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/cryptography_service.dart';
import '../../../../core/services/session_key_store.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/answer_result.dart';
import '../../domain/models/citation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

// Re-export domain models so existing imports keep working
// during migration. Prefer importing from domain directly.
export '../../domain/models/answer_result.dart';
export '../../domain/models/citation.dart';
export '../../domain/models/message.dart';
export '../../domain/models/conversation.dart';
export '../../domain/repositories/chat_repository.dart';

/// Development stub for [ChatRepository].
///
/// Returns hard-coded responses with a simulated network delay.
/// Tracks guest query counts and can simulate network errors
/// for testing.
class MockChatRepository implements ChatRepository {
  final CryptographyService _crypto;
  final SessionKeyStore _sessionKeys;

  int _guestQueryCount = 0;
  final int _guestQueryLimit = AppStrings.guestQueryLimit;
  bool _simulateNetworkError = false;

  /// Simulated server databases for E2EE
  final Map<String, String> _wrappedConversationKeys =
      {}; // conversationId: WrappedCK
  final Map<String, List<Message>> _encryptedMessages =
      {}; // conversationId: [EncryptedMessage, ...]

  MockChatRepository({
    CryptographyService? crypto,
    SessionKeyStore? sessionKeys,
  }) : _crypto = crypto ?? CryptographyService(),
       _sessionKeys = sessionKeys ?? SessionKeyStore() {
    // Seed test conversations
    _seedTestConversations();
  }

  void _seedTestConversations() {
    // We do not pre-encrypt because we don't have the AccountKey active yet
    // Load history will synthesize decrypted versions
  }

  /// The current number of guest queries sent.
  int get guestQueryCount => _guestQueryCount;

  /// Resets the guest query counter to zero.
  ///
  /// Call between integration test runs to ensure test
  /// isolation when the same [MockChatRepository] instance
  /// is reused.
  void resetGuestQueryCount() {
    _guestQueryCount = 0;
  }

  /// Enables or disables simulated network errors.
  void setSimulateNetworkError(bool simulate) {
    _simulateNetworkError = simulate;
  }

  final List<Conversation> _conversations = [
    Conversation(
      id: 'mock-conv-1',
      title: 'What is karma?',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Conversation(
      id: 'mock-conv-2',
      title: 'Explain meditation',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Conversation(
      id: 'mock-conv-3',
      title: 'The path of light',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Conversation(
      id: 'mock-conv-4',
      title: 'Ancient wisdom',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Conversation(
      id: 'mock-conv-5',
      title: 'Spiritual growth',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Conversation(
      id: 'mock-conv-6',
      title: 'Inner peace',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  @override
  Future<AnswerResult> sendQuery(
    String query, {
    String? conversationId,
    String? guestSessionId,
  }) async {
    // ... existing sendQuery logic ...
    AppLogger.i(
      'MockChatRepository: Received query',
      error: {'query': query, 'guestSessionId': guestSessionId},
    );

    await Future<void>.delayed(const Duration(seconds: 1));

    if (_simulateNetworkError) {
      AppLogger.e('MockChatRepository: Simulating network error');
      throw Exception('NetworkError');
    }

    if (guestSessionId != null) {
      AppLogger.d(
        'MockChatRepository: Guest query count: $_guestQueryCount/$_guestQueryLimit',
      );
      if (_guestQueryCount >= _guestQueryLimit) {
        AppLogger.w('MockChatRepository: Rate limit triggered');
        throw Exception('RateLimitException');
      }
      _guestQueryCount++;
    }

    final id = conversationId ?? 'mock-conv-${_conversations.length + 1}';
    if (conversationId == null && guestSessionId == null) {
      _conversations.insert(
        0,
        Conversation(
          id: id,
          title: query.length > 30 ? '${query.substring(0, 30)}...' : query,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Simulate Encryption and Storage if authenticated
    if (guestSessionId == null) {
      await _simulateEncryptionAndStore(
        id,
        query,
        'This is a mocked AI response to: "$query"',
      );
    }

    return AnswerResult(
      answer: 'This is a mocked AI response to: "$query"',
      citations: [
        Citation(
          documentId: 'mock-doc-001',
          title: 'Mock Doc',
          page: 1,
          paragraphId: 'p1',
          relevanceScore: 0.95,
          passageText: 'The soul is neither born, and nor does it die...',
        ),
      ],
      conversationId: id,
    );
  }

  /// Encrypts messages with a ConversationKey and stores them wrapped.
  Future<void> _simulateEncryptionAndStore(
    String id,
    String query,
    String answer,
  ) async {
    final ak = _sessionKeys.currentAccountKey;
    if (ak == null) {
      AppLogger.w(
        'MockChatRepository: No AccountKey active, skipping E2EE simulation',
      );
      return;
    }

    SecretKey ck;
    if (_wrappedConversationKeys.containsKey(id)) {
      ck = await _crypto.unwrapKey(_wrappedConversationKeys[id]!, ak);
    } else {
      ck = await _crypto.generateRandomKey();
      _wrappedConversationKeys[id] = await _crypto.wrapKey(ck, ak);
    }

    final queryMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final encryptedQuery = await _crypto.encryptContent(
      query,
      ck,
      aad: utf8.encode('$id:$queryMsgId'),
    );

    final answerMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final encryptedAnswer = await _crypto.encryptContent(
      answer,
      ck,
      aad: utf8.encode('$id:$answerMsgId'),
    );

    _encryptedMessages.putIfAbsent(id, () => []);
    _encryptedMessages[id]!.addAll([
      Message(
        id: queryMsgId,
        sender: 'user',
        content: encryptedQuery,
        timestamp: DateTime.now(),
      ),
      Message(
        id: answerMsgId,
        sender: 'assistant',
        content: encryptedAnswer,
        timestamp: DateTime.now(),
      ),
    ]);

    AppLogger.d(
      'MockChatRepository: Sent and stored encrypted messages for $id',
    );
  }

  @override
  Future<List<Message>> loadHistory(String conversationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_simulateNetworkError) {
      AppLogger.e(
        'MockChatRepository: Simulating network error in loadHistory',
      );
      throw Exception('NetworkError');
    }

    final ak = _sessionKeys.currentAccountKey;
    // Check if we have dynamically generated encrypted messages from earlier test steps
    if (_encryptedMessages.containsKey(conversationId) && ak != null) {
      final wrappedCk = _wrappedConversationKeys[conversationId]!;
      final ck = await _crypto.unwrapKey(wrappedCk, ak);

      final decryptedList = <Message>[];
      for (final msg in _encryptedMessages[conversationId]!) {
        final decryptedContent = await _crypto.decryptContent(
          msg.content,
          ck,
          aad: utf8.encode('$conversationId:${msg.id}'),
        );
        decryptedList.add(msg.copyWith(content: decryptedContent));
      }
      AppLogger.d('MockChatRepository: Successfully decrypted history');
      return decryptedList;
    }

    // Fallback: return hardcoded mock history if E2EE wasn't established (or for older seeded conversation tests)
    return [
      Message(
        id: 'msg1',
        sender: 'user',
        content: 'Hello',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: 'msg2',
        sender: 'assistant',
        content: 'Hi! How can I help?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ];
  }

  @override
  Future<List<Conversation>> getConversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.from(_conversations);
  }

  @override
  Future<void> deleteConversation(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _conversations.removeWhere((conv) => conv.id == id);
  }

  @override
  Future<String> exportConversation(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final conv = _conversations.firstWhere((c) => c.id == id);
    return 'Exported Conversation: ${conv.title}\nID: ${conv.id}\nCreated: ${conv.createdAt}';
  }
}
