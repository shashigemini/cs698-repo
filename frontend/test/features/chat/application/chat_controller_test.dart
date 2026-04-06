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
    test('CC-01: Correct defaults', () async {
      await createAndInit(guestQueries: 3);
      final state = container.read(chatControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.guestQueriesRemaining, 3);
    });

    test('CC-02: Guest skips conversatons', () async {
      await createAndInit(userId: null);
      verifyNever(() => mockRepo.getConversations());
    });
  });

  group('ChatController: sendQuery Logic', () {
    test('CC-05: Loader blocks', () async {
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
    });

    test('CC-06/07: Rate limit blocking', () async {
      final controller = await createAndInit(guestQueries: 0);
      
      // Force state update if it hasn't landed
      if (container.read(chatControllerProvider).guestQueriesRemaining != 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await controller.sendQuery('q1', guestSessionId: 'g1');
      expect(container.read(chatControllerProvider).rateLimitExceeded, isTrue);

      clearInteractions(mockRepo);
      await controller.sendQuery('q2');
      verifyNever(() => mockRepo.sendQuery(any(), guestSessionId: any(named: 'guestSessionId')));
    });

    test('CC-08: Optimistic auth success', () async {
      final controller = await createAndInit(userId: 'u1');
      final completer = Completer<AnswerResult>();
      when(() => mockRepo.sendQuery(any(), conversationId: any(named: 'conversationId')))
          .thenAnswer((_) => completer.future);

      final f = controller.sendQuery('hi');
      await Future.delayed(Duration.zero);
      expect(container.read(chatControllerProvider).messages.length, 1);

      completer.complete(const AnswerResult(answer: 'bot', conversationId: 'c1'));
      await f;
      expect(container.read(chatControllerProvider).messages.length, 2);
    });

    test('CC-09: Guest decrement', () async {
      var count = 3;
      mockGuestService = MockGuestService();
      when(() => mockGuestService.getQueriesRemaining()).thenAnswer((_) => count);
      when(() => mockGuestService.incrementUsage()).thenAnswer((_) async { count--; });
      when(() => mockAuthRepo.currentUserId).thenReturn(null);
      when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(null));

      initContainer() {
        container = ProviderContainer(
          overrides: [
            chatRepositoryProvider.overrideWithValue(mockRepo),
            guestServiceProvider.overrideWithValue(mockGuestService),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
        );
      }
      initContainer();
      await container.read(chatControllerProvider.notifier).initialized;

      await container.read(chatControllerProvider.notifier).sendQuery('q', guestSessionId: 'g1');
      expect(container.read(chatControllerProvider).guestQueriesRemaining, 2);
    });
  });

  group('ChatController: Conversation management', () {
    test('CC-14/15/16: loadConversation', () async {
      final controller = await createAndInit();
      final history = [Message(id: '1', sender: 'u', content: 'c', timestamp: DateTime.now())];
      when(() => mockRepo.loadHistory('id')).thenAnswer((_) async => history);

      await controller.loadConversation('id');
      expect(container.read(chatControllerProvider).conversationId, 'id');

      when(() => mockRepo.loadHistory('err')).thenAnswer((_) async => throw Exception());
      await controller.loadConversation('err');
      expect(container.read(chatControllerProvider).error, isNotNull);
    });

    test('CC-19/20: deleteConversation', () async {
      final controller = await createAndInit();
      when(() => mockRepo.deleteConversation(any())).thenAnswer((_) async {});
      when(() => mockRepo.getConversations()).thenAnswer((_) async => []);
      when(() => mockRepo.loadHistory('active')).thenAnswer((_) async => []);
      
      await controller.loadConversation('active');
      await controller.deleteConversation('other');
      expect(container.read(chatControllerProvider).conversationId, 'active');

      await controller.deleteConversation('active');
      expect(container.read(chatControllerProvider).conversationId, isNull);
    });

    test('CC-22/23: export', () async {
      final controller = await createAndInit();
      when(() => mockRepo.exportConversation('id')).thenAnswer((_) async => 'data');
      expect(await controller.exportConversation('id'), 'data');
    });
  });
}
