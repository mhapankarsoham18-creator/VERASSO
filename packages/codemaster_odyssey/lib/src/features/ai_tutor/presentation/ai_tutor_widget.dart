import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../ai_tutor/domain/tutor_hint_model.dart';

/// A widget that displays AI Tutor hints and provides an interface for code analysis.
class AiTutorWidget extends StatelessWidget {
  /// List of hints to display.
  final List<TutorHint> hints;

  /// Callback triggered when the analyze button is pressed.
  final VoidCallback onAnalyze;

  /// Whether code analysis is currently in progress.
  final bool isAnalyzing;

  /// Creates an [AiTutorWidget] instance.
  const AiTutorWidget({
    super.key,
    required this.hints,
    required this.onAnalyze,
    this.isAnalyzing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.95),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00E5FF),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.black,
                      size: 24,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2.seconds, delay: 3.seconds),
              const SizedBox(width: 12),
              const Text(
                'AI TUTOR',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (isAnalyzing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF00E5FF),
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: onAnalyze,
                  tooltip: 'Analyze Code',
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (hints.isEmpty && !isAnalyzing)
            const Text(
              'I am ready to analyze your code, Apprentice.',
              style: TextStyle(color: Colors.white70),
            )
          else
            ...hints.map((hint) {
              Color color;
              IconData icon;

              switch (hint.severity) {
                case HintSeverity.error:
                  color = Colors.redAccent;
                  icon = Icons.error_outline;
                  break;
                case HintSeverity.warning:
                  color = Colors.orangeAccent;
                  icon = Icons.warning_amber;
                  break;
                case HintSeverity.info:
                  color = Colors.lightBlueAccent;
                  icon = Icons.info_outline;
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  border: Border(left: BorderSide(color: color, width: 4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hint.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          if (hint.codeSnippet != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                hint.codeSnippet!,
                                style: const TextStyle(
                                  fontFamily: 'FiraCode',
                                  color: Colors.white54,
                                  fontSize: 12,
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: 0.1);
            }),
        ],
      ),
    );
  }
}
