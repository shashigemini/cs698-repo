import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/guest_service.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/chat/application/chat_controller.dart';
import 'package:frontend/features/chat/application/chat_state.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/domain/models/answer_result.dart';
import 'package:frontend/features/chat/domain/models/conversation.dart';
import 'package:frontend/features/chat/domain/models/message.dart';
import 'package:frontend/features/chat/domain/repositories/chat_repository.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockGuestService extends Mock implements GuestService {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockChatRepository mockRepo;
  late MockGuestService mockGuestService;
  late MockAuthRepository mockAuthRepo;

  setUpAll(() {
    AppLogger.init(level: Level.off);
    registerFallbackValue(const AnswerResult(answer: ''));
  });

  Future<ChatController> createAndInit({String? userId, int guestQueries = 3}) async {
    mockRepo = MockChatRepository();
    mockGuestService = MockGuestService();
    mockAuthRepo = MockAuthRepository();

    when(() => mockGuestService.getQueriesRemaining()).thenReturn(guestQueries);
    when(() => mockGuestService.incrementUsage()).thenAnswer((_) async {});
    when(() => mockRepo.getConversations()).thenAnswer((_) async => <Conversation>[]);
    when(() => mockRepo.loadHistory(any())).thenAnswer((_) async => <Message>[]);
    when(() => mockRepo.sendQuery(any(), 
      conversationId: any(named: 'conversationId'), 
      guestSessionId: any(named: 'guestSessionId')))
        .thenAnswer((_) async => const AnswerResult(answer: 'mock-ans'));
    
    // Stable auth state to prevent listener refreshes
    when(() => mockAuthRepo.currentUserId).thenReturn(userId);
    when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(userId));

    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockRepo),
        guestServiceProvider.overrideWithValue(mockGuestService),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
    );

    final controller = container.read(chatControllerProvider.notifier);
    await controller.initialized;
    
    // Ensure state synchronizes
    await Future.delayed(const Duration(milliseconds: 50));
    
    return controller;
  }

  tearDown(() {
    container.dispose();
  });

  group('ChatController: Initialization', () {
    test('CC-01: Initial state has correct defaults', () async {
      await createAndInit(guestQueries: 3);
      final state = container.read(chatControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages, isEmpty);
      expect(state.error, isNull);
      expect(state.rateLimitExceeded, isFalse);
      expect(state.guestQueriesRemaining, 3);
    });

    test('CC-02: Guest user initialization skips conversation fetch', () async {
      await createAndInit(userId: null);
      verifyNever(() => mockRepo.getConversations());
      expect(container.read(chatControllerProvider).recentConversations, isEmpty);
    });

    test('CC-03: Authenticated user initialization fetches conversations', () async {
      final conversations = [
        Conversation(id: '1', title: 'A', createdAt: DateTime(2023)),
        Conversation(id: '2', title: 'B', createdAt: DateTime(2023)),
      ];
      mockRepo = MockChatRepository();
      when(() => mockRepo.getConversations()).thenAnswer((_) async => conversations);
      when(() => mockAuthRepo.currentUserId).thenReturn('user1');
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value('user1'));
      when(() => mockGuestService.getQueriesRemaining()).thenReturn(3);

      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          guestServiceProvider.overrideWithValue(mockGuestService),
        ],
      );

      await container.read(chatControllerProvider.notifier).initialized;
      expect(container.read(chatControllerProvider).recentConversations.length, 2);
    });

    test('CC-04: Init error is caught and logged (no crash)', () async {
      mockRepo = MockChatRepository();
      when(() => mockRepo.getConversations()).thenThrow(Exception('DB fail'));
      when(() => mockAuthRepo.currentUserId).thenReturn('u1');
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value('u1'));
      when(() => mockGuestService.getQueriesRemaining()).thenReturn(3);

      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          guestServiceProvider.overrideWithValue(mockGuestService),
        ],
      );

      await container.read(chatControllerProvider.notifier).initialized;
      // Should not crash, and should keep default state for recent convo
      expect(container.read(chatControllerProvider).recentConversations, isEmpty);
    });
  });

  group('ChatController: sendQuery Logic', () {
    test('CC-05: Blocked when isLoading is true', () async {
      final controller = await createAndInit();
      final completer = Completer<AnswerResult>();
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenAnswer((_) => completer.future);

      final f1 = controller.sendQuery('q1');
      expect(container.read(chatControllerProvider).isLoading, isTrue);

      await controller.sendQuery('q2'); 

      completer.complete(const AnswerResult(answer: 'ans'));
      await f1;

      verify(() => mockRepo.sendQuery('q1', conversationId: any(named: 'conversationId'))).called(1);
      verifyNever(() => mockRepo.sendQuery('q2', conversationId: any(named: 'conversationId')));
    });

    test('CC-06: Blocked when rateLimitExceeded is true', () async {
      final controller = await createAndInit(guestQueries: 3);
      // Manually trigger rate limit flag through an error simulation to set limits
      when(() => mockRepo.sendQuery(any(), guestSessionId: any(named: 'guestSessionId')))
          .thenThrow(Exception('RateLimitException'));
      await controller.sendQuery('q1', guestSessionId: 'g');
      
      expect(container.read(chatControllerProvider).rateLimitExceeded, isTrue);
      
      clearInteractions(mockRepo);
      await controller.sendQuery('q2');
      verifyNever(() => mockRepo.sendQuery(any(), guestSessionId: any(named: 'guestSessionId')));
    });

    test('CC-07: Guest with zero remaining triggers rate limit', () async {
      final controller = await createAndInit(guestQueries: 0);
      
      if (container.read(chatControllerProvider).guestQueriesRemaining != 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await controller.sendQuery('q1', guestSessionId: 'g1');
      
      final state = container.read(chatControllerProvider);
      expect(state.rateLimitExceeded, isTrue);
      expect(state.error, contains('Rate limit exceeded'));
      expect(state.guestQueriesRemaining, 0);
    });

    test('CC-08: Authenticated success — user message added optimistically', () async {
      final controller = await createAndInit(userId: 'u1');
      final completer = Completer<AnswerResult>();
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenAnswer((_) => completer.future);

      final f = controller.sendQuery('hi');
      await Future.delayed(Duration.zero);
      expect(container.read(chatControllerProvider).messages.length, 1);
      expect(container.read(chatControllerProvider).messages[0].sender, 'user');
      expect(container.read(chatControllerProvider).isLoading, isTrue);

      completer.complete(const AnswerResult(answer: 'bot', conversationId: 'c1'));
      await f;
      
      expect(container.read(chatControllerProvider).messages.length, 2);
      expect(container.read(chatControllerProvider).messages[1].sender, 'assistant');
      expect(container.read(chatControllerProvider).isLoading, isFalse);
    });

    test('CC-09: Guest success — decrements guest queries', () async {
      var count = 3;
      mockGuestService = MockGuestService();
      when(() => mockGuestService.getQueriesRemaining()).thenAnswer((_) => count);
      when(() => mockGuestService.incrementUsage()).thenAnswer((_) async { count--; });
      when(() => mockAuthRepo.currentUserId).thenReturn(null);
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          guestServiceProvider.overrideWithValue(mockGuestService),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
      );
      
      final controller = container.read(chatControllerProvider.notifier);
      await controller.initialized;

      await controller.sendQuery('q', guestSessionId: 'g1');
      expect(container.read(chatControllerProvider).guestQueriesRemaining, 2);
    });

    test('CC-10: New conversation triggers fetchRecentConversations', () async {
      final controller = await createAndInit(userId: 'u1');
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenAnswer((_) async => const AnswerResult(answer: 'ans', conversationId: 'c1'));
      
      // Initially called in _init, so clear interactions
      clearInteractions(mockRepo);
      
      await controller.sendQuery('q');
      
      verify(() => mockRepo.getConversations()).called(1);
    });

    test('CC-11: Existing conversation does NOT trigger fetchRecentConversations', () async {
      final controller = await createAndInit(userId: 'u1');
      
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenAnswer((_) async => const AnswerResult(answer: 'ans', conversationId: 'c1'));
      // Pre-load conversation
      await controller.loadConversation('c1');
      clearInteractions(mockRepo);
      
      await controller.sendQuery('q2');
      
      verifyNever(() => mockRepo.getConversations());
    });

    test('CC-12: Network error sets error state', () async {
      final controller = await createAndInit();
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenThrow(Exception('NetworkError'));

      await controller.sendQuery('q');
      
      expect(container.read(chatControllerProvider).isLoading, isFalse);
      expect(container.read(chatControllerProvider).error, contains('NetworkError'));
    });

    test('CC-13: RateLimitException error sets rate limit state', () async {
      final controller = await createAndInit();
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenThrow(Exception('RateLimitException'));

      await controller.sendQuery('q');
      
      final state = container.read(chatControllerProvider);
      expect(state.rateLimitExceeded, isTrue);
      expect(state.error, contains('Rate limit exceeded'));
      expect(state.guestQueriesRemaining, 0);
    });
  });

  group('ChatController: Conversation management', () {
    test('CC-14: loadConversation - Success loads messages', () async {
      final controller = await createAndInit();
      final history = [Message(id: '1', sender: 'user', content: 'hello', timestamp: DateTime.now())];
      when(() => mockRepo.loadHistory('conv-1')).thenAnswer((_) async => history);

      await controller.loadConversation('conv-1');
      
      final state = container.read(chatControllerProvider);
      expect(state.messages.length, 1);
      expect(state.isLoading, isFalse);
      expect(state.conversationId, 'conv-1');
    });

    test('CC-15: loadConversation - Loading state during fetch', () async {
      final controller = await createAndInit();
      final completer = Completer<List<Message>>();
      when(() => mockRepo.loadHistory('conv-1')).thenAnswer((_) => completer.future);

      final f = controller.loadConversation('conv-1');
      
      expect(container.read(chatControllerProvider).isLoading, isTrue);
      expect(container.read(chatControllerProvider).messages, isEmpty);
      expect(container.read(chatControllerProvider).conversationId, 'conv-1');
      
      completer.complete([]);
      await f;
    });

    test('CC-16: loadConversation - Error sets failure message', () async {
      final controller = await createAndInit();
      when(() => mockRepo.loadHistory('conv-err')).thenThrow(Exception());

      await controller.loadConversation('conv-err');
      
      final state = container.read(chatControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('Failed to load conversation history'));
      expect(state.messages, isEmpty);
    });

    test('CC-17: fetchRecentConversations - Success updates list', () async {
      final controller = await createAndInit();
      final convs = [
         Conversation(id: 'a', title: 'abc', createdAt: DateTime(2023)),
         Conversation(id: 'b', title: 'def', createdAt: DateTime(2023)),
         Conversation(id: 'c', title: 'ghi', createdAt: DateTime(2023))
      ];
      when(() => mockRepo.getConversations()).thenAnswer((_) async => convs);
      
      await controller.fetchRecentConversations();
      
      expect(container.read(chatControllerProvider).recentConversations.length, 3);
    });

    test('CC-18: fetchRecentConversations - Error is silently caught', () async {
      final controller = await createAndInit();
      when(() => mockRepo.getConversations()).thenThrow(Exception());
      
      await controller.fetchRecentConversations();
      // Should not throw, list remains same (empty as created)
      expect(container.read(chatControllerProvider).recentConversations, isEmpty);
    });

    test('CC-19: deleteConversation - Deleting non-active conversation refreshes list', () async {
      final controller = await createAndInit();
      when(() => mockRepo.loadHistory('A')).thenAnswer((_) async => []);
      await controller.loadConversation('A');
      
      when(() => mockRepo.deleteConversation('B')).thenAnswer((_) async {});
      when(() => mockRepo.getConversations()).thenAnswer((_) async => []);
      
      await controller.deleteConversation('B');
      
      expect(container.read(chatControllerProvider).conversationId, 'A');
      verify(() => mockRepo.getConversations()).called(1);
    });

    test('CC-20: deleteConversation - Deleting active conversation resets to new', () async {
      final controller = await createAndInit();
      when(() => mockRepo.loadHistory('A')).thenAnswer((_) async => []);
      await controller.loadConversation('A');
      
      when(() => mockRepo.deleteConversation('A')).thenAnswer((_) async {});
      when(() => mockRepo.getConversations()).thenAnswer((_) async => []);
      
      await controller.deleteConversation('A');
      
      expect(container.read(chatControllerProvider).conversationId, isNull);
      expect(container.read(chatControllerProvider).messages, isEmpty);
      expect(container.read(chatControllerProvider).error, isNull);
    });

    test('CC-21: deleteConversation - Error is silently caught', () async {
      final controller = await createAndInit();
      when(() => mockRepo.deleteConversation('X')).thenThrow(Exception());
      
      await controller.deleteConversation('X');
      // No crash
      expect(container.read(chatControllerProvider).error, isNull);
    });

    test('CC-22: exportConversation - Success returns export string', () async {
      final controller = await createAndInit();
      when(() => mockRepo.exportConversation('id')).thenAnswer((_) async => 'exported data');
      
      expect(await controller.exportConversation('id'), 'exported data');
    });

    test('CC-23: exportConversation - Error returns null', () async {
      final controller = await createAndInit();
      when(() => mockRepo.exportConversation('id')).thenThrow(Exception());
      
      expect(await controller.exportConversation('id'), isNull);
    });

    test('CC-24: newConversation - Resets all conversation state', () async {
      final controller = await createAndInit();
      // Dirty the state
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenThrow(Exception('RateLimitException'));
      await controller.sendQuery('query'); // Sets error & rateLimit
      await controller.loadConversation('some-id');
      
      controller.newConversation(); // Should clear it
      
      final state = container.read(chatControllerProvider);
      expect(state.messages, isEmpty);
      expect(state.conversationId, isNull);
      expect(state.error, isNull);
      expect(state.rateLimitExceeded, isFalse);
    });

    test('CC-25: resetError - Clears error field', () async {
      final controller = await createAndInit();
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenThrow(Exception('Random Error'));
      await controller.sendQuery('query'); 
      expect(container.read(chatControllerProvider).error, isNotNull);
      
      controller.resetError();
      expect(container.read(chatControllerProvider).error, isNull);
    });

    test('CC-26: resetError - No-op when error is already null', () async {
      final controller = await createAndInit();
      controller.resetError();
      expect(container.read(chatControllerProvider).error, isNull);
    });
  });
}
