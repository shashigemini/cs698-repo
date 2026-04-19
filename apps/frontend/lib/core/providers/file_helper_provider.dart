import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/file_helper.dart';

part 'file_helper_provider.g.dart';

@riverpod
FileHelperInstance fileHelper(Ref ref) {
  return const FileHelperInstance();
}

class FileHelperInstance {
  const FileHelperInstance();

  Future<void> downloadString(String content, String filename) async {
    await FileHelper.downloadString(content, filename);
  }
}
