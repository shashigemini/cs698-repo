import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadStringImpl(String content, String filename) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(content);

  // Using Share.shareXFiles with ignore as it is the standard way in many versions
  // but the lint suggests SharePlus.
  // ignore: deprecated_member_use
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'Exported Conversation',
  );
}
