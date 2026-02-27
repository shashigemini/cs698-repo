import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/core/services/storage_provider.dart';
import 'package:frontend/core/services/mock_storage_service.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/auth/domain/models/token_pair.dart';
import '../../../helpers/crypto_mocks.dart';
import 'package:mocktail/mocktail.dart';

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

  late MockAuthRepository mockAuthRepo;
  late MockChatRepository mockChatRepo;
  late MockStorageService mockStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockStorageService();

    mockAuthRepo = MockAuthRepository(
      storage: mockStorage,
      crypto: FakeCryptographyService(),
      sessionKeys: MockSessionKeyStore(),
    );
    mockChatRepo = MockChatRepository();
  });

  /// Helper to pump the HomeScreen directly, bypassing GoRouter.
  Future<ProviderContainer> pumpHomeScreen(WidgetTester tester) async {
    // Pre-authenticate as guest so the HomeScreen renders.
    mockAuthRepo.setUser(AppStrings.guestUserId);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        chatRepositoryProvider.overrideWithValue(mockChatRepo),
        storageServiceProvider.overrideWithValue(mockStorage),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        // Wrap with Router.withConfig to satisfy context.go calls.
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Initial frame
    await tester.pump();
    // Wait for the async 500ms MockChatRepository load to finish initializing the controller
    await tester.pump(const Duration(milliseconds: 600));

    addTearDown(() => container.dispose());

    return container;
  }

  group('Guest UI Flow', () {
    testWidgets('Drawer shows Guest User and query count', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpHomeScreen(tester);

      // Open drawer
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Guest User'), findsOneWidget);
      expect(find.text('3 queries remaining'), findsOneWidget);
    });

    testWidgets('Chat input and send button are present', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpHomeScreen(tester);

      expect(find.byKey(const Key('chat_input_field')), findsOneWidget);
      expect(find.byKey(const Key('chat_send_button')), findsOneWidget);
    });

    testWidgets('Sending a query adds user message to list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpHomeScreen(tester);

      // Enter text and send
      final inputFinder = find.byKey(const Key('chat_input_field'));
      await tester.tap(inputFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.enterText(inputFinder, 'What is dharma?');
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pump(); // Trigger send

      // User message should appear
      expect(find.text('What is dharma?'), findsOneWidget);

      // Wait for mock response delay (1s)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(); // Rebuild with response

      // AI response should appear
      expect(
        find.textContaining('This is a mocked AI response'),
        findsOneWidget,
      );
    });

    testWidgets('Rate limit modal appears after exceeding guest limit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpHomeScreen(tester);

      // Send 3 queries to exhaust the guest limit.
      for (var i = 0; i < 3; i++) {
        final inputFinder = find.byKey(const Key('chat_input_field'));
        await tester.tap(inputFinder);
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        await tester.enterText(inputFinder, 'Query $i');
        await tester.tap(find.byKey(const Key('chat_send_button')));
        await tester.pump(); // Start send
        await tester.pump(const Duration(seconds: 2)); // Wait for response
        await tester.pump(); // Rebuild
      }

      // 4th query should trigger rate limit based on >= boundary rule
      final inputFinder = find.byKey(const Key('chat_input_field'));
      await tester.tap(inputFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.enterText(inputFinder, 'Query 4');
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pump(); // Start send
      await tester.pump(const Duration(seconds: 2)); // Wait for error
      await tester.pump(); // Rebuild with error state

      // The rate limit banner should appear
      expect(find.byKey(const Key('rate_limit_banner')), findsOneWidget);

      // The rate limit modal dialog should appear
      expect(find.text('Reached daily limit'), findsOneWidget);
      expect(find.byKey(const Key('signin_from_modal_button')), findsOneWidget);
    });
  });
}
