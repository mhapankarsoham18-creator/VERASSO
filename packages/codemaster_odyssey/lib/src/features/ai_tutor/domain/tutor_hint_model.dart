/// Severity levels for AI Tutor hints.
enum HintSeverity {
  /// General information or encouragement.
  info,

  /// Potential issues that might cause bugs.
  warning,

  /// Syntax errors or logical flaws that will cause failure.
  error,
}

/// Represents a hint or piece of feedback from the AI Tutor.
class TutorHint {
  /// The feedback message to display to the user.
  final String message;

  /// The severity level of the hint.
  final HintSeverity severity;

  /// Optional code snippet or example related to the hint.
  final String? codeSnippet;

  /// Creates a [TutorHint] instance.
  const TutorHint({
    required this.message,
    required this.severity,
    this.codeSnippet,
  });
}
