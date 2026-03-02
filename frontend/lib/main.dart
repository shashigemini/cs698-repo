import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_application/secure_application.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/local_settings_store.dart';
import 'core/services/security_service.dart';
import 'core/presentation/widgets/error_boundary.dart';
import 'theme/app_theme.dart';

import 'package:logger/logger.dart';
import 'core/utils/app_logger.dart';

/// Application entry point.
///
/// Wraps the widget tree in a [ProviderScope] so Riverpod
/// providers are available throughout the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init(level: Level.info);

  // Initialize freeRASP for root/jailbreak detection
  await SecurityService.init();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SpiritualQaApp(),
    ),
  );
}

/// Root widget for the Spiritual Q&A application.
///
/// Sets up [MaterialApp.router] with the [GoRouter] from
/// [goRouterProvider], applies the light/dark themes from
/// [AppTheme], and follows the system theme mode.
class SpiritualQaApp extends ConsumerWidget {
  /// Creates a [SpiritualQaApp].
  const SpiritualQaApp({super.key, this.disableSecurity = false});

  /// Whether to disable security features (for testing).
  final bool disableSecurity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(goRouterProvider);

    return GlobalErrorHandler(
      child: MaterialApp.router(
        title: AppStrings.appTitle,
        routerConfig: router,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          if (disableSecurity || kIsWeb)
            return child ?? const SizedBox.shrink();

          // Wrap the app to obscure screenshots in the background (app switcher)
          return SecureApplication(
            nativeRemoveDelay: 100,
            onNeedUnlock: (secure) async {
              secure?.unlock();
              return null;
            },
            child: Builder(
              builder: (context) {
                return ErrorBoundary(
                  child: SecureGate(
                    blurr: 20,
                    opacity: 0.1,
                    lockedBuilder: (context, secureNotifier) =>
                        const Center(child: CircularProgressIndicator()),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
