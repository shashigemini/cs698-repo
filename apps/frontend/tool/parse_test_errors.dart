// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Runs a specific Flutter test and extracts only the exception and failure reasons
/// cleanly without Unicode/command-line artifacting.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tool/parse_test_errors.dart <test_file>');
    exit(1);
  }

  final file = File(args.first);
  if (!file.existsSync()) {
    print('❌ Test file not found: \${args.first}');
    return;
  }

  print('Running tests and extracting errors cleanly...');

  final process = await Process.start('flutter', [
    'test',
    file.path,
    '--reporter',
    'json',
  ], runInShell: true);

  var foundError = false;

  final dumpFile = File('a11y_error_dump.txt');
  if (dumpFile.existsSync()) {
    dumpFile.deleteSync();
  }

  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      if (!line.startsWith('{')) {
        return; // Ignore standard flutter build compilation info
      }

      try {
        final data = jsonDecode(line) as Map<String, dynamic>;

        if (data['type'] == 'print') {
          final message = data['message']?.toString() ?? '';
          if (message.contains('Expected') ||
              message.contains('Actual') ||
              message.contains('Which')) {
            dumpFile.writeAsStringSync(
              '\n[PRINT DETAIL]\n$message\n',
              mode: FileMode.append,
            );
          }
        }

        if (data['type'] == 'error') {
          foundError = true;
          // Log the whole data object for deep inspection
          final fullJson = JsonEncoder.withIndent('  ').convert(data);

          dumpFile.writeAsStringSync(
            '\n================ ERROR EVENT ================\n$fullJson\n',
            mode: FileMode.append,
          );
          print('Error event dumped to a11y_error_dump.txt');
        }
      } catch (_) {
        // Ignore parse exceptions
      }
    },
  );

  await process.exitCode;

  if (!foundError) {
    print('✅ No errors found in test output!');
  }
}
