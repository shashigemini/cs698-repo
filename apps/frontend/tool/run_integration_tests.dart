// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Standardized script to execute Flutter integration tests.
/// On Windows: runs with `-d windows`.
/// On Linux (devcontainer): runs with `-d linux` under `xvfb-run`
/// for headless GUI testing via a virtual framebuffer.
/// Runs tests sequentially to avoid resource locks and cleanly parses
/// the JSON output in-memory.
Future<void> main(List<String> args) async {
  final timeoutMinutes = int.tryParse(
    Platform.environment['INTEGRATION_TEST_TIMEOUT_MINUTES'] ?? '',
  );
  final perTestTimeout = Duration(
    minutes: timeoutMinutes != null && timeoutMinutes > 0 ? timeoutMinutes : 15,
  );

  final integrationTestDir = Directory('integration_test');
  if (!integrationTestDir.existsSync()) {
    print('❌ integration_test directory not found.');
    exit(1);
  }

  String? logFilePath;
  String? targetPath;

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--log-file' && i + 1 < args.length) {
      logFilePath = args[++i];
    } else if (!args[i].startsWith('--')) {
      targetPath = args[i];
    }
  }

  IOSink? logSink;
  if (logFilePath != null) {
    print('📝 Logging output to: $logFilePath');
    logSink = File(logFilePath).openWrite(mode: FileMode.write);
  }

  void log(String message) {
    print(message);
    logSink?.writeln(message);
  }

  List<File> testFiles;
  if (targetPath != null) {
    final specificFile = File(targetPath);
    if (specificFile.existsSync()) {
      testFiles = [specificFile];
    } else if (Directory(targetPath).existsSync()) {
      testFiles = Directory(targetPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .toList();
    } else {
      log('❌ Path not found: $targetPath');
      await logSink?.close();
      exit(1);
    }
  } else {
    testFiles = integrationTestDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        .toList();
  }

  if (testFiles.isEmpty) {
    log('⚠️ No integration tests found.');
    await logSink?.close();
    return;
  }
  testFiles.sort((a, b) => a.path.compareTo(b.path));

  log(
    'Found ${testFiles.length} integration tests. Running sequentially '
    '(per-test timeout: ${perTestTimeout.inMinutes}m)...\n',
  );
  var failedCount = 0;

  for (final file in testFiles) {
    log('=' * 80);
    log('🚀 Running ${file.path}...');
    log('=' * 80);

    // Platform-adaptive device and executable
    final isLinux = Platform.isLinux;
    final device = isLinux ? 'linux' : 'windows';

    final List<String> command;
    if (isLinux) {
      // Use xvfb-run for headless GUI on Linux (devcontainer)
      command = [
        'xvfb-run',
        '--auto-servernum',
        'flutter',
        'test',
        file.path,
        '-d',
        device,
        '--reporter',
        'json',
      ];
    } else {
      command = [
        'flutter',
        'test',
        file.path,
        '-d',
        device,
        '--reporter',
        'json',
      ];
    }

    final executable = command.first;
    final arguments = command.sublist(1);

    final process = await Process.start(
      executable,
      arguments,
      runInShell: Platform.isWindows,
    );

    var errorCount = 0;
    var timedOut = false;

    final stdoutFuture = process.stdout
        .transform(systemEncoding.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isEmpty) return;

      if (!line.startsWith('{')) {
        log(line);
        return;
      }

      try {
        final data = jsonDecode(line) as Map<String, dynamic>;

        if (data['type'] == 'testStart' && data['test'] != null) {
          final testName = data['test']['name'].toString();
          if (!testName.startsWith('loading ')) {
            log('▶️  $testName');
          }
        }

        if (data['type'] == 'print' && data.containsKey('message')) {
          log('   💬 ${data['message']}');
        }

        if (data['type'] == 'error' ||
            data['result'] == 'error' ||
            data['success'] == false) {
          errorCount++;
          log('\n❌ TEST ERROR DETECTED:');
          if (data.containsKey('error')) {
            log('ERROR: ${data['error'].toString().trim()}');
          }
          if (data.containsKey('stackTrace')) {
            log('STACK TRACE:\n${data['stackTrace'].toString().trim()}');
          }
          log('-' * 80 + '\n');
        }
      } catch (_) {
        log(line);
      }
    }).asFuture<void>();

    final stderrFuture = process.stderr.transform(utf8.decoder).listen((error) {
      log('⚠️ STDERR: $error');
    }).asFuture<void>();

    final exitCode = await process.exitCode.timeout(
      perTestTimeout,
      onTimeout: () async {
        timedOut = true;
        log(
          '⏱️ Timeout after ${perTestTimeout.inMinutes} minutes for ${file.path}. '
          'Attempting to terminate test process...',
        );
        process.kill(ProcessSignal.sigterm);
        await Future<void>.delayed(const Duration(seconds: 5));
        process.kill(ProcessSignal.sigkill);
        return 124;
      },
    );
    await Future.wait([stdoutFuture, stderrFuture]);

    if (exitCode != 0 || errorCount > 0 || timedOut) {
      log('❌ ${file.path} FAILED.');
      failedCount++;
    } else {
      log('✅ ${file.path} PASSED.');
    }
    log('');
  }

  log('=' * 80);
  if (failedCount > 0) {
    log('❌ $failedCount test suite(s) failed.');
    await logSink?.close();
    exit(1);
  } else {
    log('✅ All integration tests completed successfully.');
  }
  await logSink?.close();
}
