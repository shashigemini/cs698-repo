import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/chat/application/chat_controller.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';

import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/core/services/storage_provider.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import '../../../helpers/crypto_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cryptography_service.dart';
import 'package:frontend/core/services/local_settings_store.dart';

class MockStorage extends Mock implements StorageService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TokenPair(
        accessToken: '',
        refreshToken: '',
        accessExpiresAt: DateTime.now(),
      ),
    );
  });

  late CryptographyService mockCrypto;
  late MockSessionKeyStore mockSessionKeys;
  late MockRecoveryService mockRecoveryService;
  late MockStorage mockStorage;
  late MockAuthRepository mockAuthRepo;
  late MockChatRepository mockChatRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockStorage();
    // Stub the storage methods
    when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
    when(() => mockStorage.deleteTokens()).thenAnswer((_) async {});
    when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
    when(() => mockStorage.getCsrfToken()).thenAnswer((_) async => null);

    mockSessionKeys = MockSessionKeyStore();
    when(() => mockSessionKeys.currentAccountKey).thenReturn(null);
    mockCrypto = FakeCryptographyService();
    mockRecoveryService = MockRecoveryService();

    mockAuthRepo = MockAuthRepository(
      storage: mockStorage,
      crypto: mockCrypto,
      sessionKeys: mockSessionKeys,
      recovery: mockRecoveryService,
    );
    mockChatRepo = MockChatRepository(
      crypto: mockCrypto,
      sessionKeys: mockSessionKeys,
    );
  });

  /// Helper to pump the HomeScreen directly as an authenticated user.
  Future<ProviderContainer> pumpAuthenticatedHome(WidgetTester tester) async {
    // Pre-authenticate as a real user (not guest).
    mockAuthRepo.setUser('testuser@example.com');

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

    await tester.pump(); // Initial frame
    return ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
  }

  group('Authenticated Chat Flow', () {
    testWidgets('Sending query shows loading then AI response', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = await pumpAuthenticatedHome(tester);

      // Type and send
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Test query',
      );
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pump(); // Trigger send

      // Verify loading state
      expect(container.read(chatControllerProvider).isLoading, true);
      expect(find.text('Test query'), findsOneWidget);

      // Wait for mock response
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(); // Rebuild

      // Loading done; AI message visible
      final finalState = container.read(chatControllerProvider);
      debugPrint(
        'TEST: finalState.isLoading=${finalState.isLoading}, messages=${finalState.messages.length}',
      );
      for (var m in finalState.messages) {
        debugPrint('TEST: msg sender=${m.sender}, content=${m.content}');
      }
      expect(finalState.isLoading, false);
      expect(
        find.textContaining('This is a mocked AI response'),
        findsOneWidget,
      );
    });

    testWidgets('Network error shows SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpAuthenticatedHome(tester);

      // Enable network error simulation
      mockChatRepo.setSimulateNetworkError(true);

      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Fail query',
      );
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pump(); // Trigger send
      await tester.pump(const Duration(seconds: 2)); // Wait for error
      await tester.pump(); // Rebuild with error

      // SnackBar with error message
      expect(find.text('Exception: NetworkError'), findsOneWidget);
    });

    testWidgets('Drawer shows Authenticated User and logout button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpAuthenticatedHome(tester);

      // Open drawer
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('testuser@example.com'), findsOneWidget);
      expect(find.byKey(const Key('logout_menu_item')), findsOneWidget);
    });
  });
}
