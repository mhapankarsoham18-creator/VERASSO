/// Represents a single step in a debugging session, capturing the line and variable state.
class DebugStep {
  /// The line number currently being executed.
  final int lineNumber;

  /// The state of all watched variables at this step.
  final List<VariableState> variables;

  /// Creates a [DebugStep] instance.
  const DebugStep({required this.lineNumber, required this.variables});
}

/// The state of a single variable during execution.
class VariableState {
  /// Name of the variable.
  final String name;

  /// String representation of the variable's value.
  final String value;

  /// Type name of the variable (e.g., 'int', 'String').
  final String type;

  /// The line number where this variable was last modified.
  final int lineChanged;

  /// Creates a [VariableState] instance.
  const VariableState({
    required this.name,
    required this.value,
    required this.type,
    required this.lineChanged,
  });
}
