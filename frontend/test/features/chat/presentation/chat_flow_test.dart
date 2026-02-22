import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/chat/application/chat_controller.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockChatRepository mockChatRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockChatRepo = MockChatRepository();
  });

  /// Helper to pump the HomeScreen directly as an authenticated user.
  Future<ProviderContainer> pumpAuthenticatedHome(WidgetTester tester) async {
    // Pre-authenticate as a real user (not guest).
    mockAuthRepo.setUser('testuser@example.com');

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        chatRepositoryProvider.overrideWithValue(mockChatRepo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump(); // Initial frame
    return container;
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
      expect(container.read(chatControllerProvider).isLoading, false);
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
