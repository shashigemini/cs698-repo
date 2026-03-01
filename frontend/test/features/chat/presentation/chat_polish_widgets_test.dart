import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/core/services/storage_provider.dart';
import '../../../helpers/crypto_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStorage extends Mock implements StorageService {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockChatRepository mockChatRepo;
  late MockStorage mockStorage;
  late MockRecoveryService mockRecoveryService;

  setUpAll(() {
    registerFallbackValue(
      TokenPair(
        accessToken: '',
        refreshToken: '',
        accessExpiresAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockStorage();
    when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
    when(() => mockStorage.deleteTokens()).thenAnswer((_) async {});

    final mockSessionKeys = MockSessionKeyStore();
    when(() => mockSessionKeys.currentAccountKey).thenReturn(null);
    final mockCrypto = FakeCryptographyService();
    mockRecoveryService =
        MockRecoveryService(); // Initialize mockRecoveryService

    mockAuthRepo = MockAuthRepository(
      storage: mockStorage,
      crypto: mockCrypto,
      sessionKeys: mockSessionKeys,
      recovery: mockRecoveryService, // Add recovery service
    );
    mockChatRepo = MockChatRepository(
      crypto: mockCrypto,
      sessionKeys: mockSessionKeys,
    );
  });

  Future<void> pumpHome(WidgetTester tester) async {
    mockAuthRepo.setUser('test@example.com');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          chatRepositoryProvider.overrideWithValue(mockChatRepo),
          storageServiceProvider.overrideWithValue(mockStorage),
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Chat Polish Widget Tests', () {
    testWidgets('Assistant bubble shows share button and citations', (
      tester,
    ) async {
      await pumpHome(tester);

      // Send a query to get an assistant response
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify Share button exists
      expect(find.byIcon(LucideIcons.share2), findsOneWidget);

      // Verify Citation exists
      expect(find.textContaining('Mock Doc (p. 1)'), findsOneWidget);
    });

    testWidgets('Tapping citation opens bottom sheet with passage', (
      tester,
    ) async {
      await pumpHome(tester);

      // Send query
      await tester.enterText(find.byType(TextField), 'Query');
      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap citation
      await tester.tap(find.textContaining('Mock Doc (p. 1)'));
      await tester.pumpAndSettle();

      // Verify Bottom Sheet content
      expect(find.text('Scripture Verse'), findsOneWidget);
      expect(
        find.text('The soul is neither born, and nor does it die...'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping history item in drawer loads conversation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpHome(tester);

      // Open drawer
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      // Verify recent conversations are fetched
      expect(find.text('What is karma?'), findsOneWidget);

      // Tap a history item
      await tester.tap(find.text('What is karma?'));
      await tester.pumpAndSettle(); // Wait for drawer to close

      // Verify drawer closed
      expect(find.text('test@example.com'), findsNothing);

      // Wait for history to load
      await tester.pumpAndSettle();

      // Verify loaded message (Mock history returns "Hello" and "Hi!")
      expect(find.text('Hi! How can I help?'), findsOneWidget);
    });
  });
}
