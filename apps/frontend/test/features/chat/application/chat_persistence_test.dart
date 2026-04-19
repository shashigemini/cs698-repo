import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/application/chat_controller.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:frontend/features/auth/application/auth_controller.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/core/services/cryptography_service.dart';
import 'package:frontend/core/services/session_key_store.dart';
import 'package:frontend/core/services/recovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements StorageService {}
class MockCrypto extends Mock implements CryptographyService {
  @override
  Future<SecretKey> deriveLocalMasterKey(String password, List<int> salt) async {
    return SecretKey([1, 2, 3]);
  }
  @override
  Future<String> deriveAuthToken(SecretKey lmk) async => 'mock-token';
  @override
  Future<SecretKey> generateRandomKey() async => SecretKey([4, 5, 6]);
  @override
  Future<String> wrapKey(SecretKey k, SecretKey w, {List<int>? aad}) async => 'wrapped';
  @override
  Future<SecretKey> expandKey(SecretKey k) async => SecretKey([7, 8, 9]);
}

class FakeSessionKeys extends SessionKeyStore {
  @override
  SessionKeyState build() => const SessionKeyState();
}

class MockRecovery extends Mock implements RecoveryService {}

class MockRepo extends MockChatRepository {
  @override
  Future<void> deleteConversation(String id) async {}
}

void main() {
  group('ChatController Persistence', () {
    late MockChatRepository mockChatRepo;
    late MockAuthRepository mockAuthRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockChatRepo = MockRepo();
      mockAuthRepo = MockAuthRepository(
        storage: MockStorage(),
        crypto: MockCrypto(),
        sessionKeys: FakeSessionKeys(),
        recovery: MockRecovery(),
        useDelay: false,
      );
    });

    Future<ProviderContainer> createContainer() async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockChatRepo),
          authControllerProvider.overrideWithValue(mockAuthRepo.currentUserId),
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

    test('loads persistent guest history on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'guestMessages': '[{"id":"1","sender":"user","content":"Hello","timestamp":"2026-04-19T10:00:00Z"}]',
      });
      mockAuthRepo.setUser(AppStrings.guestUserId);

      final container = await createContainer();
      await container.read(chatControllerProvider.notifier).initialized;

      final state = container.read(chatControllerProvider);
      expect(state.messages, hasLength(1));
      expect(state.messages.first.content, equals('Hello'));
    });

    test('persists guest history after query', () async {
      mockAuthRepo.setUser(AppStrings.guestUserId);
      final container = await createContainer();
      container.listen(chatControllerProvider, (previous, next) {});
      await container.read(chatControllerProvider.notifier).initialized;

      await container
          .read(chatControllerProvider.notifier)
          .sendQuery('Test Query', guestSessionId: 'guest-id');

      final prefs = await SharedPreferences.getInstance();
      final savedMessages = prefs.getString('guestMessages');
      expect(savedMessages, isNotNull);
      expect(savedMessages, contains('Test Query'));
      expect(savedMessages, contains('mocked AI response')); // From MockChatRepository
    });

    test('clears guest history on newConversation', () async {
      SharedPreferences.setMockInitialValues({
        'guestMessages': '[{"id":"1","sender":"user","content":"Hello","timestamp":"2026-04-19T10:00:00Z"}]',
      });
      mockAuthRepo.setUser(AppStrings.guestUserId);

      final container = await createContainer();
      await container.read(chatControllerProvider.notifier).initialized;

      container.read(chatControllerProvider.notifier).newConversation();

      final state = container.read(chatControllerProvider);
      expect(state.messages, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('guestMessages'), isNull);
    });
  });
}
