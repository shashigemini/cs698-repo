// ignore_for_file: avoid_print
import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('SacredWisdom');

  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('\${record.level.name}: \${record.time}: \${record.message}');
    });
  }

  static void d(String message) => _logger.config(message);
  static void i(String message) => _logger.info(message);
  static void w(String message) => _logger.warning(message);
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }
}
