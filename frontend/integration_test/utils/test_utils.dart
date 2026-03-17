import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/cryptography_provider.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../test/helpers/crypto_mocks.dart';

/// Standardizes app initialization for integration tests.
///
/// Disables security features to prevent [SecureGate] hangs and
/// overrides cryptography with [FakeCryptographyService] for speed.
Future<void> buildTestApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        cryptographyServiceProvider.overrideWithValue(
          FakeCryptographyService(),
        ),
      ],
      child: const SpiritualQaApp(disableSecurity: true),
    ),
  );

  // Wait for splash screen (2s) and transitions
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// Wipes local storage for clean test state.
Future<void> wipeStorage() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}
