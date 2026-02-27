// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Standardized script to execute Flutter integration tests on Windows.
/// Runs tests sequentially to avoid resource locks and cleanly parses
/// the JSON output in-memory, avoiding UTF-16LE file string encoding issues.
Future<void> main(List<String> args) async {
  final integrationTestDir = Directory('integration_test');
  if (!integrationTestDir.existsSync()) {
    print('❌ integration_test directory not found.');
    exit(1);
  }

  List<File> testFiles;
  if (args.isNotEmpty) {
    final specificFile = File(args.first);
    if (!specificFile.existsSync()) {
      print('❌ Specific test file not found: ${args.first}');
      exit(1);
    }
    testFiles = [specificFile];
  } else {
    testFiles = integrationTestDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        .toList();
  }

  if (testFiles.isEmpty) {
    print('⚠️ No integration tests found.');
    return;
  }

  print(
    'Found ${testFiles.length} integration tests. Running sequentially...\n',
  );
  var failedCount = 0;

  for (final file in testFiles) {
    print('=' * 80);
    print('🚀 Running ${file.path}...');
    print('=' * 80);

    final process = await Process.start('flutter', [
      'test',
      file.path,
      '-d',
      'windows',
      '--reporter',
      'json',
    ], runInShell: true);

    var errorCount = 0;

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isEmpty) return;

          if (!line.startsWith('{')) {
            // Pass through non-JSON build output safely
            print(line);
            return;
          }

          try {
            final data = jsonDecode(line) as Map<String, dynamic>;

            // Print friendly test progress
            if (data['type'] == 'testStart' && data['test'] != null) {
              final testName = data['test']['name'].toString();
              if (!testName.startsWith('loading ')) {
                print('▶️  $testName');
              }
            }

            // Catch and format errors
            if (data['type'] == 'error' ||
                data['result'] == 'error' ||
                data['success'] == false) {
              errorCount++;
              print('\n❌ TEST ERROR DETECTED:');
              print(data.toString());
              if (data.containsKey('error')) {
                print(data['error'].toString().trim());
              }
              if (data.containsKey('stackTrace')) {
                print(data['stackTrace'].toString().trim());
              }
              print('-' * 80 + '\n');
            }
          } catch (_) {
            // Fallback for unexpected JSON structure
            print(line);
          }
        });

    process.stderr.transform(utf8.decoder).listen((error) {
      print('⚠️ STDERR: $error');
    });

    final exitCode = await process.exitCode;

    if (exitCode != 0 || errorCount > 0) {
      print('❌ ${file.path} FAILED.');
      failedCount++;
    } else {
      print('✅ ${file.path} PASSED.');
    }
    print('');
  }

  print('=' * 80);
  if (failedCount > 0) {
    print('❌ $failedCount test suite(s) failed.');
    exit(1);
  } else {
    print('✅ All integration tests completed successfully.');
  }
}
