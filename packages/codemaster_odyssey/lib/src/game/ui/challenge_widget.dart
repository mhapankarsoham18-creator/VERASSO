import 'package:flutter/material.dart';

/// A modal overlay that presents a multiple-choice coding challenge.
class CodeChallengeWidget extends StatefulWidget {
  /// The challenge data map with 'question', 'options', 'correct_answer'.
  final Map<String, dynamic> challengeData;

  /// Called when the player selects the correct answer.
  final VoidCallback onSolve;

  /// Called when the player selects a wrong answer (for penalty).
  final VoidCallback? onWrongAnswer;

  /// Creates a [CodeChallengeWidget].
  const CodeChallengeWidget({
    super.key,
    required this.challengeData,
    required this.onSolve,
    this.onWrongAnswer,
  });

  @override
  State<CodeChallengeWidget> createState() => _CodeChallengeWidgetState();
}

class _CodeChallengeWidgetState extends State<CodeChallengeWidget> {
  int _attempts = 0;
  String? _wrongAnswer;

  @override
  Widget build(BuildContext context) {
    final options = widget.challengeData['options'] as List<String>? ?? [];

    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: Colors.cyan, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CODE CHALLENGE',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (_attempts > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Attempts: $_attempts',
                    style: TextStyle(
                      color: Colors.red.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black,
                child: Text(
                  widget.challengeData['question'] ?? 'Fix the broken logic:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...options.map((opt) {
                final isWrong = _wrongAnswer == opt;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isWrong ? Colors.red : Colors.cyan,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: isWrong
                            ? Colors.red.withAlpha(40)
                            : Colors.transparent,
                      ),
                      onPressed: () => _onOptionSelected(opt),
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: isWrong ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _onOptionSelected(String option) {
    if (option == widget.challengeData['correct_answer']) {
      widget.onSolve();
    } else {
      setState(() {
        _attempts++;
        _wrongAnswer = option;
      });
      widget.onWrongAnswer?.call();

      // Clear wrong-answer highlight after a delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _wrongAnswer = null);
        }
      });
    }
  }
}
