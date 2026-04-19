import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/providers/file_helper_provider.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:frontend/core/services/storage_provider.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/features/admin/data/providers/admin_repository_provider.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/domain/models/conversation.dart';
import 'package:frontend/features/chat/domain/models/message.dart';
import 'package:frontend/features/chat/domain/repositories/chat_repository.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/crypto_mocks.dart';

class MockStorage extends Mock implements StorageService {}

class MockAdminRepository extends Mock implements AdminRepository {}

class MockFileHelper extends Mock implements FileHelperInstance {}

class MockChatRepository extends Mock implements ChatRepository {}

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
  late MockAuthRepository mockAuthRepo;
  late MockChatRepository mockChatRepo;
  late MockAdminRepository mockAdminRepo;
  late MockFileHelper mockFileHelper;

  const conversationId = 'conv-123';
  final seededConversation = Conversation(
    id: conversationId,
    title: 'A seeded conversation',
    createdAt: DateTime(2026, 4, 18),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    mockStorage = MockStorage();
    when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
    when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
    when(() => mockStorage.deleteTokens()).thenAnswer((_) async {});

    mockAuthRepo = MockAuthRepository(
      storage: mockStorage,
      crypto: FakeCryptographyService(),
      sessionKeys: FakeSessionKeyStore(),
      recovery: FakeRecoveryService(),
    );
    mockAuthRepo.setUser('test@example.com');

    mockChatRepo = MockChatRepository();
    when(
      () => mockChatRepo.getConversations(),
    ).thenAnswer((_) async => [seededConversation]);
    when(() => mockChatRepo.loadHistory(conversationId)).thenAnswer(
      (_) async => <Message>[],
    );
    when(() => mockChatRepo.deleteConversation(conversationId)).thenAnswer(
      (_) async {},
    );
    when(() => mockChatRepo.exportConversation(conversationId)).thenAnswer(
      (_) async => '# Exported conversation',
    );

    mockAdminRepo = MockAdminRepository();
    mockFileHelper = MockFileHelper();
    when(() => mockFileHelper.downloadString(any(), any())).thenAnswer(
      (_) async {},
    );
  });

  Future<void> pumpSettingsWithRouter(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Route', key: ValueKey('home'))),
        ),
      ],
    );

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
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
  }

  testWidgets(
    'tapping a history row loads the selected conversation and navigates to /home',
    (tester) async {
      await pumpSettingsWithRouter(tester);

      final historyItem = find.byKey(const ValueKey('history_item_$conversationId'));
      expect(historyItem, findsOneWidget);

      await tester.tap(historyItem);
      await tester.pumpAndSettle();

      verify(() => mockChatRepo.loadHistory(conversationId)).called(1);
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
    },
  );

  testWidgets('export and delete do not navigate to /home', (tester) async {
    await pumpSettingsWithRouter(tester);

    expect(find.byKey(const ValueKey('history_item_$conversationId')), findsOneWidget);

    await tester.tap(find.byTooltip('Export').first);
    await tester.pumpAndSettle();

    verify(() => mockChatRepo.exportConversation(conversationId)).called(1);
    expect(find.byKey(const ValueKey('home')), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();

    verify(() => mockChatRepo.deleteConversation(conversationId)).called(1);
    expect(find.byKey(const ValueKey('home')), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
