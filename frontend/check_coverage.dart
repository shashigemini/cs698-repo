import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('No coverage file found.');
    return;
  }

  final lines = file.readAsLinesSync();
  String? currentFile;
  int linesFound = 0;
  int linesHit = 0;
  List<int> missingLines = [];

  int totalFound = 0;
  int totalHit = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final lineNum = int.tryParse(parts[0]) ?? 0;
        final hitCount = int.tryParse(parts[1]) ?? 0;
        linesFound++;
        if (hitCount > 0) {
          linesHit++;
        } else {
          missingLines.add(lineNum);
        }
      }
    } else if (line == 'end_of_record') {
      if (currentFile != null) {
        final percentage = linesFound == 0
            ? 100.0
            : (linesHit / linesFound) * 100;
        if (linesFound > 0 && percentage < 100) {
          print(
            '${percentage.toStringAsFixed(1)}% ($linesHit/$linesFound) - $currentFile',
          );
          if (currentFile.contains('screen.dart') ||
              currentFile.contains('validators.dart')) {
            print('  Missing: $missingLines');
          }
        }
        totalFound += linesFound;
        totalHit += linesHit;
      }
      currentFile = null;
      linesFound = 0;
      linesHit = 0;
      missingLines.clear();
    }
  }

  final totalPercentage = totalFound == 0
      ? 100.0
      : (totalHit / totalFound) * 100;
  print(
    '\nOverall Coverage: ${totalPercentage.toStringAsFixed(1)}% ($totalHit/$totalFound lines)',
  );
}
