import 'file_helper_stub.dart'
    if (dart.library.html) 'file_helper_web.dart'
    if (dart.library.io) 'file_helper_mobile.dart';

abstract class FileHelper {
  /// Downloads or shares a string as a file with the given [filename].
  static Future<void> downloadString(String content, String filename) =>
      downloadStringImpl(content, filename);
}
