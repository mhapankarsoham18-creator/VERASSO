// ignore_for_file: avoid_print
import 'dart:io';

Future<void> main() async {
  final file = File('coverage/lcov.info');
  if (!await file.exists()) {
    print('coverage/lcov.info not found');
    return;
  }

  final lines = await file.readAsLines();
  int totalLines = 0;
  int coveredLines = 0;

  for (final line in lines) {
    if (line.startsWith('LF:')) {
      totalLines += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      coveredLines += int.parse(line.substring(3));
    }
  }

  if (totalLines == 0) {
    print('No lines found');
    return;
  }

  final percentage = (coveredLines / totalLines) * 100;
  print('Total Rows: $totalLines');
  print('Covered Rows: $coveredLines');
  print('Coverage: ${percentage.toStringAsFixed(2)}%');
}
