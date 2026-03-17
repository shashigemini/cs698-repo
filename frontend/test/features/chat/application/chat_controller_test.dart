import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/application/chat_controller.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/core/services/storage_provider.dart';
import 'package:frontend/core/services/mock_storage_service.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/crypto_mocks.dart';

void main() {
  group('ChatController', () {
    Future<ProviderContainer> createContainer({
      ChatRepository? chatRepository,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(MockStorageService()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (chatRepository != null)
            chatRepositoryProvider.overrideWithValue(chatRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('initial state is correct', () async {
      final container = await createContainer();
      final state = container.read(chatControllerProvider);

      expect(state.isLoading, isFalse);
      expect(state.messages, isEmpty);
      expect(state.error, isNull);
      expect(state.rateLimitExceeded, isFalse);
      expect(state.guestQueriesRemaining, equals(AppStrings.guestQueryLimit));
    });

    test('sendQuery updates state correctly on success', () async {
      final container = await createContainer();
      container.listen(chatControllerProvider, (previous, next) {});

      final controller = container.read(chatControllerProvider.notifier);
      await controller.initialized;
      final future = controller.sendQuery('Test query');

      // State should be loading, with optimistic user message
      var state = container.read(chatControllerProvider);
      expect(state.isLoading, isTrue);
      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'Test query');
      expect(state.messages.first.sender, 'user');

      await future;

      // State should not be loading, with assistant response
      state = container.read(chatControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.length, 2);
      expect(state.messages.last.sender, 'assistant');
      expect(state.messages.last.content, isNotEmpty);
    });

    test('sendQuery handles rate limit error for guests', () async {
      final container = await createContainer();
      final controller = container.read(chatControllerProvider.notifier);
      await controller.initialized;

      // Send queries as guest until limit is reached
      final limit = AppStrings.guestQueryLimit;
      for (var i = 0; i < limit; i++) {
        await container
            .read(chatControllerProvider.notifier)
            .sendQuery('Query $i', guestSessionId: 'guest-session');
      }

      // One more query triggers rate limit (count >= limit)
      await container
          .read(chatControllerProvider.notifier)
          .sendQuery('Rate limit query', guestSessionId: 'guest-session');

      final state = container.read(chatControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, 'Rate limit exceeded');
      expect(state.rateLimitExceeded, isTrue);
      expect(state.guestQueriesRemaining, 0);
    });

    test('sendQuery (authenticated) does NOT reset guest budget', () async {
      final container = await createContainer();
      final controller = container.read(chatControllerProvider.notifier);
      await controller.initialized;
      container.listen(chatControllerProvider, (previous, next) {});

      final initial = AppStrings.guestQueryLimit;
      expect(
        container.read(chatControllerProvider).guestQueriesRemaining,
        initial,
      );

      // Simulate exhausting 1 query as guest
      await container
          .read(chatControllerProvider.notifier)
          .sendQuery('G1', guestSessionId: 'g1');
      expect(
        container.read(chatControllerProvider).guestQueriesRemaining,
        initial - 1,
      );

      // Now send as authenticated (no guest ID)
      await container.read(chatControllerProvider.notifier).sendQuery('Auth1');

      // Should STILL be decreased value, not reset
      expect(
        container.read(chatControllerProvider).guestQueriesRemaining,
        initial - 1,
      );
    });

    test('loadConversation updates state correctly on success', () async {
      final container = await createContainer();
      container.listen(chatControllerProvider, (previous, next) {});

      final controller = container.read(chatControllerProvider.notifier);
      await controller.initialized;
      final future = controller.loadConversation('conv-123');

      var state = container.read(chatControllerProvider);
      expect(state.isLoading, isTrue);
      expect(state.messages, isEmpty);
      expect(state.conversationId, 'conv-123');

      await future;

      state = container.read(chatControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages, isNotEmpty);
      expect(state.messages.length, 2);
    });

    test('loadConversation handles failure correctly', () async {
      // Create a specific container overriding chatRepositoryProvider with a failing repo
      final myMockSessionKeys = MockSessionKeyStore();
      when(() => myMockSessionKeys.currentAccountKey).thenReturn(null);
      final mockRepo = MockChatRepository(
        crypto: FakeCryptographyService(),
        sessionKeys: myMockSessionKeys,
      );
      mockRepo.setSimulateNetworkError(true);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(MockStorageService()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          chatRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(chatControllerProvider, (previous, next) {});

      final controller = container.read(chatControllerProvider.notifier);
      await controller.initialized;
      await controller.loadConversation('bad-id');

      final state = container.read(chatControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, 'Failed to load conversation history');
      expect(state.messages, isEmpty);
    });

    test('resetError clears error state', () async {
      final container = await createContainer();
      final controller = container.read(chatControllerProvider.notifier);
      await controller.initialized;
      controller.resetError();
      expect(container.read(chatControllerProvider).error, isNull);
    });
  });
}
