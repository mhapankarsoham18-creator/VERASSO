import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_tutor/domain/tutor_hint_model.dart';

/// Provider for the [AiTutorRepository] instance.
final aiTutorRepositoryProvider = Provider<AiTutorRepository>((ref) {
  return AiTutorRepository();
});

/// Repository responsible for analyzing code and providing tutoring hints.
class AiTutorRepository {
  /// Analyzes the provided [code] (Python) and returns a list of [TutorHint]s.
  List<TutorHint> analyzeCode(String code) {
    final List<TutorHint> hints = [];

    // 1. Check for missing colons in control flow
    // Regex matches lines starting with if/else/elif/for/while/def/class that DON'T end with :
    final missingColonRegex = RegExp(
      r'^\s*(if|else|elif|for|while|def|class)\b.*[^:]\s*$',
      multiLine: true,
    );
    for (final match in missingColonRegex.allMatches(code)) {
      hints.add(
        TutorHint(
          message:
              "It looks like you're missing a colon `:` at the end of this line.",
          severity: HintSeverity.error,
          codeSnippet: match.group(0)?.trim(),
        ),
      );
    }

    // 2. Check for assignment in condition (if x = 5)
    final assignmentInConditionRegex = RegExp(r'if\s+\w+\s*=[^=]');
    if (assignmentInConditionRegex.hasMatch(code)) {
      hints.add(
        const TutorHint(
          message: "In Python, use `==` for comparison. `=` is for assignment.",
          severity: HintSeverity.error,
          codeSnippet: "if x == 5:",
        ),
      );
    }

    // 3. Check for print without parentheses (Python 2 style)
    final printNoParensRegex = RegExp(r'print\s+(?![\(])');
    if (printNoParensRegex.hasMatch(code)) {
      hints.add(
        const TutorHint(
          message: "Python 3 requires parentheses for `print()`.",
          severity: HintSeverity.warning,
          codeSnippet: 'print("message")',
        ),
      );
    }

    // 4. General Encouragement if no errors
    if (hints.isEmpty && code.isNotEmpty) {
      hints.add(
        const TutorHint(
          message: "Your syntax looks clean! Try running the code.",
          severity: HintSeverity.info,
        ),
      );
    }

    return hints;
  }
}
