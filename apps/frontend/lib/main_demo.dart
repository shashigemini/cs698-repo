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
import 'features/chat/data/providers/chat_repository_provider.dart';
import 'features/chat/data/providers/api_chat_repository_provider.dart';
import 'main.dart';

void main() async {
  final logCollector = LoggerLogCollector();
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(logCollector: logCollector),
    );
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  
  await AppLogger.init(level: Level.trace, additionalOutput: logCollector); // High verbosity for demo

  // Security service is still used but could be relaxed if needed
  await SecurityService.init();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Enable demo mode
        isDemoModeProvider.overrideWithValue(true),
        // Connect to real backend
        chatRepositoryProvider.overrideWith((ref) => ref.watch(apiChatRepositoryProvider)),
      ],
      child: const SpiritualQaApp(),
    ),
  );
}
