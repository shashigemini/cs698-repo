import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/local_settings_store.dart';
import 'core/services/security_service.dart';
import 'core/utils/app_logger.dart';
import 'main.dart';

void main() async {
  MarionetteBinding.ensureInitialized();
  await AppLogger.init(level: Level.trace); // High verbosity for dev

  await SecurityService.init();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SpiritualQaApp(),
    ),
  );
}
