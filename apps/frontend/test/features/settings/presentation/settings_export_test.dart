import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/chat/data/providers/chat_repository_provider.dart';
import 'package:frontend/features/chat/data/repositories/mock_chat_repository.dart';
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
    mockChatRepo = MockChatRepository();
    mockAdminRepo = MockAdminRepository();
    mockFileHelper = MockFileHelper();

    when(() => mockFileHelper.downloadString(any(), any()))
        .thenAnswer((_) async {});
  });

  Future<void> pumpSettingsScreen(WidgetTester tester) async {
    mockAuthRepo.setUser('test@example.com');
    
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

    await tester.pump(); // Initial load
    await tester.pump(const Duration(seconds: 1)); // Wait for history fetch
    await tester.pump(); // Final rebuild
  }

  group('SettingsScreen Export Test', () {
    testWidgets('Tapping export button triggers export flow', (tester) async {
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
  });
}
