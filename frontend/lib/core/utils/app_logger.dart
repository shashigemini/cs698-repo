import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Centralized logging utility leveraging the `logger` package.
///
/// Supports colored console output in test/debug environments and
/// persistent file logging in all environments.
class AppLogger {
  static Logger? _logger;
  static bool _initialized = false;

  /// Initializes the logging system.
  ///
  /// Must be called before [runApp] in `main.main()`.
  /// [level] defines the minimum verbosity. Default is [Level.info].
  static Future<void> init({Level level = Level.info, LogOutput? additionalOutput}) async {
    if (_initialized) return;

    var outputs = <LogOutput>[];

    // Console output for debug/profile mode
    if (kDebugMode || kProfileMode) {
      outputs.add(ConsoleOutput());
    }
    
    if (additionalOutput != null) {
      outputs.add(additionalOutput);
    }

    // File output (not supported on Web in the same way, path_provider might throw)
    if (!kIsWeb) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final logFile = File('${docDir.path}/app_logs.txt');
        outputs.add(FileOutput(file: logFile));
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'AppLogger initialization warning: Failed to get log file directory: $e',
          );
        }
      }
    }

    _logger = Logger(
      level: level,
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: MultiOutput(outputs),
    );

    _initialized = true;
    _logger?.i('AppLogger initialized at level $level');
  }

  /// Ensures [AppLogger] has been initialized. Provide a fallback if not.
  static Logger get instance {
    if (!_initialized) {
      // Fallback for tests or edge cases where init() might be skipped.
      return Logger(level: Level.warning, printer: PrettyPrinter());
    }
    return _logger!;
  }

  /// Convenience method for fine-grained debug details.
  static void t(dynamic message, {Object? error, StackTrace? stackTrace}) {
    instance.t(message, error: error, stackTrace: stackTrace);
  }

  /// Convenience method for development diagnostics.
  static void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Convenience method for general info.
  static void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Convenience method for warnings.
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Convenience method for critical errors.
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  /// Convenience method for fatal errors.
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }

  /// Redacts sensitive keys from a [Map].
  ///
  /// Useful for logging request/body data without leaking credentials.
  static Map<String, dynamic> scrub(Map<String, dynamic> data) {
    const sensitiveKeys = {
      'password',
      'access_token',
      'refresh_token',
      'token',
      'authorization',
      'auth',
      'api_key',
      'apikey',
      'secret',
    };

    final result = Map<String, dynamic>.from(data);
    for (final key in result.keys) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        result[key] = '[REDACTED]';
      } else if (result[key] is Map<String, dynamic>) {
        result[key] = scrub(result[key] as Map<String, dynamic>);
      } else if (result[key] is List) {
        result[key] = (result[key] as List).map((val) {
          if (val is Map<String, dynamic>) {
            return scrub(val);
          }
          return val;
        }).toList();
      }
    }
    return result;
  }
}
