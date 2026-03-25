// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('❌ Coverage file not found. Run flutter test --coverage first.');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  var hit = 0;
  var found = 0;

  for (final line in lines) {
    if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  final percentage = (hit / found) * 100;
  print('📊 Total Line Coverage: \${percentage.toStringAsFixed(2)}% (\$hit/\$found)');

  if (percentage < 80) {
    print('⚠️ Coverage is below 80%!');
    // exit(1); // Optional: fail CI if coverage is too low
  }
}
