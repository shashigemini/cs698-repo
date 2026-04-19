import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/domain/models/conversation.dart';
import 'package:frontend/features/chat/domain/models/message.dart';
import 'package:frontend/features/chat/domain/repositories/chat_repository.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/core/services/storage_provider.dart';
import 'package:frontend/features/admin/data/providers/admin_repository_provider.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import 'package:frontend/core/providers/file_helper_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/crypto_mocks.dart';

class MockStorage extends Mock implements StorageService {}
class MockAdminRepository extends Mock implements AdminRepository {}
class MockFileHelper extends Mock implements FileHelperInstance {}
class MockChatRepository extends Mock implements ChatRepository {}

class MockLoggedInAuthRepo extends MockAuthRepository {
  MockLoggedInAuthRepo({
    required super.storage,
    required super.crypto,
    required super.sessionKeys,
    required super.recovery,
  });

  @override
  String? get currentUserId => 'test-user-id';

  @override
  Stream<String?> get authStateChanges => Stream.value('test-user-id');
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TokenPair(
        accessToken: '',
        refreshToken: '',
        accessExpiresAt: DateTime.now(),
      ),
    );
    registerCryptoFallbackValues();
  });

  late MockStorage mockStorage;
  late MockLoggedInAuthRepo mockAuthRepo;
  late MockChatRepository mockChatRepo;
  late MockAdminRepository mockAdminRepo;
  late MockFileHelper mockFileHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockStorage();
    when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
    when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
    when(() => mockStorage.deleteTokens()).thenAnswer((_) async {});

    mockAuthRepo = MockLoggedInAuthRepo(
      storage: mockStorage,
      crypto: FakeCryptographyService(),
      sessionKeys: FakeSessionKeyStore(),
      recovery: FakeRecoveryService(),
    );
    mockChatRepo = MockChatRepository();
    mockAdminRepo = MockAdminRepository();
    mockFileHelper = MockFileHelper();

    when(() => mockFileHelper.downloadString(any(), any()))
        .thenAnswer((_) async {});

    when(() => mockChatRepo.getConversations()).thenAnswer((_) async => []);
    when(() => mockChatRepo.loadHistory(any())).thenAnswer((_) async => <Message>[]);
    when(() => mockChatRepo.deleteConversation(any())).thenAnswer((_) async {});
    when(() => mockChatRepo.exportConversation(any()))
        .thenAnswer((_) async => '# conversation export');
  });

  Future<void> pumpSettingsScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          chatRepositoryProvider.overrideWithValue(mockChatRepo),
          storageServiceProvider.overrideWithValue(mockStorage),
          adminRepositoryProvider.overrideWithValue(mockAdminRepo),
          fileHelperProvider.overrideWithValue(mockFileHelper),
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpRouterAndOpenSettings(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        chatRepositoryProvider.overrideWithValue(mockChatRepo),
        storageServiceProvider.overrideWithValue(mockStorage),
        adminRepositoryProvider.overrideWithValue(mockAdminRepo),
        fileHelperProvider.overrideWithValue(mockFileHelper),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 3));
    container.read(goRouterProvider).go('/settings');
    await tester.pumpAndSettle();
    return container;
  }

  group('SettingsScreen Export Test', () {
    testWidgets('Tapping export button triggers export flow', (tester) async {
      final seededConversation = Conversation(
        id: 'conversation-1',
        title: 'Conversation One',
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockChatRepo.getConversations())
          .thenAnswer((_) async => [seededConversation]);

      await pumpSettingsScreen(tester);

      // Find the first export button (LucideIcons.download)
      final exportButton = find.byTooltip('Export').first;
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pump(); // Trigger export

      // Verify it shows loading or just wait for the mock delay
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Check for the success snackbar
      expect(find.text('Conversation exported'), findsOneWidget);

      // Verify mock file helper was called
      verify(() => mockFileHelper.downloadString(any(), any())).called(1);
    });

    testWidgets('Selecting history item loads conversation and navigates to /home', (
      tester,
    ) async {
      const conversationId = 'conversation-42';
      final seededConversation = Conversation(
        id: conversationId,
        title: 'Conversation Forty Two',
        createdAt: DateTime(2026, 1, 2),
      );
      when(() => mockChatRepo.getConversations())
          .thenAnswer((_) async => [seededConversation]);

      await pumpRouterAndOpenSettings(tester);

      final historyItem = find.byKey(const ValueKey('history_item_$conversationId'));
      expect(historyItem, findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(historyItem);
      await tester.pumpAndSettle();

      verify(() => mockChatRepo.loadHistory(conversationId)).called(1);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('Export and delete actions do not navigate to /home', (tester) async {
      const conversationId = 'conversation-77';
      final seededConversation = Conversation(
        id: conversationId,
        title: 'Conversation Seventy Seven',
        createdAt: DateTime(2026, 1, 3),
      );
      when(() => mockChatRepo.getConversations())
          .thenAnswer((_) async => [seededConversation]);

      await pumpRouterAndOpenSettings(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.tap(find.byTooltip('Export').first);
      await tester.pumpAndSettle();

      verify(() => mockChatRepo.exportConversation(conversationId)).called(1);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();

      verify(() => mockChatRepo.deleteConversation(conversationId)).called(1);
      expect(find.text('Conversation deleted'), findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
