import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

import '../../data/assessment_models.dart';
import '../../data/assessment_repository.dart';

/// Future provider for fetching questions for a specific quiz.
final quizQuestionsProvider =
    FutureProvider.family<List<Question>, String>((ref, quizId) {
  return ref.watch(assessmentRepositoryProvider).getQuizQuestions(quizId);
});

/// A screen for students to take a quiz associated with a course.
class QuizPlayerScreen extends ConsumerStatefulWidget {
  /// The quiz to be played.
  final Quiz quiz;

  /// Creates a [QuizPlayerScreen] instance.
  const QuizPlayerScreen({super.key, required this.quiz});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  int? _selectedOption;
  bool _isAnswerChecked = false;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.quiz.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: Text(widget.quiz.title), backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: questionsAsync.when(
          data: (questions) {
            if (questions.isEmpty) {
              return const Center(child: Text('No questions available.'));
            }

            if (_quizCompleted) return _buildResultView(questions.length);

            final currentQuestion = questions[_currentQuestionIndex];

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / questions.length,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${questions.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentQuestion.questionText,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final text = entry.value;
                    final isSelected = _selectedOption == idx;
                    final isCorrect = currentQuestion.correctOptionIndex == idx;

                    Color borderColor = Colors.white10;
                    if (_isAnswerChecked) {
                      if (isCorrect) {
                        borderColor = Colors.greenAccent;
                      } else if (isSelected) {
                        borderColor = Colors.redAccent;
                      }
                    } else if (isSelected) {
                      borderColor = Colors.blueAccent;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: _isAnswerChecked
                            ? null
                            : () => setState(() {
                                  _selectedOption = idx;
                                }),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          border: Border.all(color: borderColor),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white10,
                                child: Text(
                                  String.fromCharCode(65 + idx),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Text(text,
                                      style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedOption == null
                          ? null
                          : (_isAnswerChecked
                              ? () => _nextQuestion(questions.length)
                              : () => _checkAnswer(currentQuestion)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(_isAnswerChecked
                          ? (_currentQuestionIndex < questions.length - 1
                              ? 'Next Question'
                              : 'Finish Quiz')
                          : 'Check Answer'),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildResultView(int totalQuestions) {
    final percentage = (_score / totalQuestions * 100).toInt();
    final passed = percentage >= widget.quiz.passingScore;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? LucideIcons.trophy : LucideIcons.alertTriangle,
              size: 80,
              color: passed ? Colors.amber : Colors.redAccent,
            ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 24),
            Text(
              passed ? 'Congratulations!' : 'Almost There!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored $percentage% ($_score/$totalQuestions)',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            if (passed)
              const GlassContainer(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(LucideIcons.fileCheck,
                        color: Colors.blueAccent, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Certificate Issued!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'It has been added to your professional profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                child: const Text('Back to Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkAnswer(Question question) {
    if (_selectedOption == null) return;

    if (_selectedOption == question.correctOptionIndex) {
      _score++;
    }

    setState(() => _isAnswerChecked = true);
  }

  void _completeQuiz(int totalQuestions) async {
    setState(() => _quizCompleted = true);

    final percentage = (_score / totalQuestions * 100).toInt();
    final passed = percentage >= widget.quiz.passingScore;

    // Hook: Log Activity
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        await ProgressTrackingService().logActivity(
          userId: userId,
          activityType: 'quiz_completed',
          activityCategory: 'learning',
          metadata: {
            'quiz_id': widget.quiz.id,
            'score': percentage,
            'passed': passed,
            'title': widget.quiz.title
          },
        );

        if (passed) {
          await ProgressTrackingService().logActivity(
            userId: userId,
            activityType: 'quiz_passed',
            activityCategory: 'learning',
            metadata: {'quiz_id': widget.quiz.id, 'score': percentage},
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error logging quiz activity', error: e);
    }

    if (passed) {
      final studentId = ref.read(currentUserProvider)?.id;
      if (studentId != null) {
        await ref
            .read(assessmentRepositoryProvider)
            .issueCertificate(studentId, widget.quiz.courseId);
      }
    }
  }

  void _nextQuestion(int totalQuestions) {
    if (_currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswerChecked = false;
      });
    } else {
      _completeQuiz(totalQuestions);
    }
  }
}
