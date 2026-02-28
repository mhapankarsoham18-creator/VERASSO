import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/debugger_model.dart';

/// Provider for the [DebuggerRepository] instance.
final debuggerRepositoryProvider = Provider<DebuggerRepository>((ref) {
  return DebuggerRepository();
});

/// Repository responsible for parsing code and simulating debugger steps.
class DebuggerRepository {
  /// Parses the given [code] and returns a list of [DebugStep] objects simulating execution.
  List<DebugStep> parseAndSimulate(String code) {
    // This is a naive simulation for demonstration.
    // In a real IDE, this would interface with a real debugger (like DAP).
    final List<DebugStep> steps = [];
    final lines = code.split('\n');

    // Very simple heuristic to detect a loop or assignments
    if (code.contains('for') && code.contains('print')) {
      // Mock steps for a simple loop like:
      // for i in range(3):
      //   print(i)
      steps.add(const DebugStep(lineNumber: 1, variables: [])); // Header
      steps.add(
        const DebugStep(
          lineNumber: 2,
          variables: [
            VariableState(name: 'i', value: '0', type: 'int', lineChanged: 2),
          ],
        ),
      );
      steps.add(
        const DebugStep(
          lineNumber: 3,
          variables: [
            VariableState(name: 'i', value: '0', type: 'int', lineChanged: 2),
          ],
        ),
      );
      steps.add(
        const DebugStep(
          lineNumber: 2,
          variables: [
            VariableState(name: 'i', value: '1', type: 'int', lineChanged: 2),
          ],
        ),
      );
      steps.add(
        const DebugStep(
          lineNumber: 3,
          variables: [
            VariableState(name: 'i', value: '1', type: 'int', lineChanged: 2),
          ],
        ),
      );
      steps.add(
        const DebugStep(
          lineNumber: 2,
          variables: [
            VariableState(name: 'i', value: '2', type: 'int', lineChanged: 2),
          ],
        ),
      );
      steps.add(
        const DebugStep(
          lineNumber: 3,
          variables: [
            VariableState(name: 'i', value: '2', type: 'int', lineChanged: 2),
          ],
        ),
      );
    } else {
      // Default: one step per line
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) {
          steps.add(DebugStep(lineNumber: i + 1, variables: []));
        }
      }
    }

    return steps;
  }
}
