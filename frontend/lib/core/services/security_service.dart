import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';
import '../constants/env.dart';
import '../utils/app_logger.dart';

/// Service responsible for managing app security, such as
/// Jailbreak/Root detection, hook detection, and environment checks.
class SecurityService {
  /// Initializes freeRASP security checks.
  /// Should be called after [WidgetsFlutterBinding.ensureInitialized]
  /// and before [runApp].
  static Future<void> init() async {
    if (kIsWeb) {
      AppLogger.i('SecurityService: Skipping freeRASP on web platform.');
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      AppLogger.i(
        'SecurityService: Skipping freeRASP on unsupported platform.',
      );
      return;
    }

    // In debug mode, we might want to bypass strict security checks
    // or log them instead of crashing/exiting.
    final isTestEnvironment =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (kDebugMode && !isTestEnvironment) {
      AppLogger.i(
        'SecurityService: Running in debug mode. freeRASP checks active but warnings only.',
      );
    }

    // Use obfuscated values from Env
    try {
      final config = TalsecConfig(
        androidConfig: AndroidConfig(
          packageName: Env.androidPackageName,
          signingCertHashes: [Env.androidCertHash],
        ),
        iosConfig: IOSConfig(
          bundleIds: [Env.iosBundleId],
          teamId: Env.iosTeamId,
        ),
        watcherMail: Env.securityWatcherMail,
        isProd: !kDebugMode,
      );

      // Set up callbacks for different threat events
      final callback = ThreatCallback(
        onAppIntegrity: () => _handleThreat('App Integrity tampered'),
        onObfuscationIssues: () => _handleThreat('Obfuscation issues detected'),
        onDebug: () => _handleThreat('Debugging detected'),
        onDeviceBinding: () => _handleThreat('Device binding issues'),
        onDeviceID: () => _handleThreat('Device ID cloned'),
        onHooks: () => _handleThreat('Hooking framework detected (e.g. Frida)'),
        onPrivilegedAccess: () =>
            _handleThreat('Jailbreak/Root access detected'),
        onSimulator: () => _handleThreat('Running on Simulator/Emulator'),
        onUnofficialStore: () =>
            _handleThreat('Installed from Unofficial Store'),
      );

      // Attach listener and start Talsec
      await Talsec.instance.attachListener(callback);
      await Talsec.instance.start(config);
      AppLogger.i('SecurityService: freeRASP initialized successfully.');
    } catch (e) {
      AppLogger.e('SecurityService: Failed to initialize freeRASP: $e');
      if (!kDebugMode) {
        rethrow;
      }
      AppLogger.w(
        'SecurityService: Continuing in debug mode despite initialization failure.',
      );
    }
  }

  static void _handleThreat(String threatMessage) {
    AppLogger.e('SECURITY THREAT DETECTED: $threatMessage');

    // In production, we aggressively exit the app if a critical threat is found
    // such as Root, Frida hooks, or App tampered.
    if (!kDebugMode) {
      exit(1);
    }
  }
}
