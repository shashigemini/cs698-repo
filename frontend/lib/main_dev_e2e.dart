import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:marionette_logger/marionette_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/local_settings_store.dart';
import 'core/services/security_service.dart';
import 'core/utils/app_logger.dart';
import 'core/providers/demo_mode_provider.dart';
import 'core/network/dio_provider.dart';
import 'features/chat/data/providers/chat_repository_provider.dart';
import 'features/chat/data/providers/api_chat_repository_provider.dart';
import 'features/admin/data/repositories/api_admin_repository.dart';
import 'features/admin/data/providers/admin_repository_provider.dart';
import 'core/services/storage_provider.dart';
import 'core/services/mock_storage_service.dart';
import 'main.dart';

/// Dev/E2E entry point with Marionette MCP integration.
///
/// Connects to the real backend (Docker Compose dev environment)
/// and enables admin features including PDF upload and
/// ingestion. Uses Marionette for AI agent interaction and
/// debugging.
void main() async {
  final logCollector = LoggerLogCollector();
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(logCollector: logCollector),
    );
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  await AppLogger.init(
    level: Level.trace,
    additionalOutput: logCollector,
  );

  await SecurityService.init();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storageServiceProvider.overrideWithValue(MockStorageService()),
        // Enable demo mode (bypasses auth for admin access)
        isDemoModeProvider.overrideWithValue(true),
        // Connect to real backend API
        chatRepositoryProvider.overrideWith(
          (ref) => ref.watch(apiChatRepositoryProvider),
        ),
        adminRepositoryProvider.overrideWith((ref) {
          final dio = ref.watch(dioProvider);
          return ApiAdminRepository(dio: dio);
        }),
      ],
      child: const SpiritualQaApp(),
    ),
  );
}
