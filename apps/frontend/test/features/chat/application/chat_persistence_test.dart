import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/application/chat_controller.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ChatController Persistence', () {
    late MockChatRepository mockRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockRepo = MockRepo();
    });

    Future<ProviderContainer> createContainer() async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('loads persistent usage on initialization', () async {
      final now = DateTime.now().toUtc();
      SharedPreferences.setMockInitialValues({
        'guestQueryCount': 1,
        'lastQueryDate': now.toIso8601String(),
      });

      final container = await createContainer();
      await container.read(chatControllerProvider.notifier).initialized;

      final state = container.read(chatControllerProvider);
      expect(state.guestQueriesRemaining, equals(2));
    });

    test('resets usage on a new day', () async {
      final longAgo = DateTime(2020, 1, 1).toUtc();
      SharedPreferences.setMockInitialValues({
        'guestQueryCount': 2,
        'lastQueryDate': longAgo.toIso8601String(),
      });

      final container = await createContainer();
      await container.read(chatControllerProvider.notifier).initialized;

      final state = container.read(chatControllerProvider);
      expect(state.guestQueriesRemaining, equals(AppStrings.guestQueryLimit));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('guestQueryCount'), equals(0));
    });

    test('persists usage after query', () async {
      final container = await createContainer();
      container.listen(chatControllerProvider, (previous, next) {});
      await container.read(chatControllerProvider.notifier).initialized;

      await container
          .read(chatControllerProvider.notifier)
          .sendQuery('Test', guestSessionId: 'guest-id');

      final state = container.read(chatControllerProvider);
      expect(state.guestQueriesRemaining, equals(2));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('guestQueryCount'), equals(1));
    });
  });
}

class MockRepo extends MockChatRepository {
  @override
  Future<void> deleteConversation(String id) async {}
}
