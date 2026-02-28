import 'package:codemaster_odyssey/src/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:codemaster_odyssey/src/features/ai_tutor/domain/tutor_hint_model.dart';
import 'package:codemaster_odyssey/src/features/ai_tutor/presentation/ai_tutor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../badge/data/badge_repository.dart';
import '../../badge/presentation/badge_notification.dart';
import '../../editor/data/debugger_repository.dart';
import '../../editor/domain/debugger_model.dart';
import '../../editor/presentation/odyssey_editor.dart';
import '../../quest/data/quest_repository.dart';
import '../../quest/domain/quest_model.dart';
import '../data/adaptive_difficulty_service.dart';
import '../data/history_providers.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson_model.dart';
import '../domain/snippet_history.dart';

/// A screen that displays an interactive micro-lesson for a specific realm.
class LessonScreen extends ConsumerStatefulWidget {
  /// The ID of the realm this lesson belongs to.
  final String realmId;

  /// The unique ID of the lesson.
  final String lessonId;

  /// Creates a [LessonScreen] instance.
  const LessonScreen({
    super.key,
    required this.realmId,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  String _currentCode = '';
  String _feedbackMessage = '';
  bool _isSuccess = false;

  // AI Tutor State
  List<TutorHint> _tutorHints = [];
  bool _isAnalyzing = false;
  bool _showTutor = false;

  // Debugger State
  List<DebugStep> _debugSteps = [];
  int _currentStepIndex = -1;
  bool _isDebugging = false;

  int? get _activeLine =>
      _currentStepIndex >= 0 ? _debugSteps[_currentStepIndex].lineNumber : null;
  List<VariableState>? get _activeVariables =>
      _currentStepIndex >= 0 ? _debugSteps[_currentStepIndex].variables : null;

  @override
  Widget build(BuildContext context) {
    // Simulate fetching specific lesson - in real app, use ref.watch with family
    final lessons = ref.read(lessonRepositoryProvider).getLessonsForRealm('1');
    final lesson = lessons.first; // Mock: always get first lesson for now

    if (_currentCode.isEmpty) {
      final latestSnippetAsync = ref.watch(
        latestSnippetProvider(widget.lessonId),
      );
      latestSnippetAsync.whenData((snippet) {
        if (snippet != null && _currentCode.isEmpty) {
          setState(() {
            _currentCode = snippet.codeSnippet;
          });
        }
      });

      if (_currentCode.isEmpty) {
        _currentCode = lesson.starterCode;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // Deep space/fantasy background
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: const Color(0xFF2D2D44),
        actions: [
          IconButton(
            icon: Icon(_showTutor ? Icons.close : Icons.psychology),
            onPressed: () {
              setState(() {
                _showTutor = !_showTutor;
                if (_showTutor && _tutorHints.isEmpty) {
                  // Optional: Auto-analyze on open?
                  // _analyzeCode();
                }
              });
            },
            tooltip: 'Ask AI Tutor',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Panel: Legend/Content
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Video Placeholder
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Markdown(
                            data: lesson.markdownContent,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: Colors.white),
                              h1: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              code: GoogleFonts.firaCode(
                                backgroundColor: const Color(0xFF2D2D44),
                                color: const Color(0xFF00E5FF),
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: const Color(0xFF2D2D44),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Panel: Editor
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: OdysseyEditor(
                            initialCode: _currentCode,
                            activeLine: _activeLine,
                            variables: _activeVariables,
                            onChanged: (value) {
                              _currentCode = value;
                            },
                          ),
                        ),
                      ),
                      // Feedback Area
                      if (_feedbackMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: _isSuccess
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          child: Text(
                            _feedbackMessage,
                            style: TextStyle(
                              color: _isSuccess ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // AI Tutor Widget
                      if (_showTutor)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          child: AiTutorWidget(
                            hints: _tutorHints,
                            isAnalyzing: _isAnalyzing,
                            onAnalyze: _analyzeCode,
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            if (_isDebugging)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _nextStep,
                                  icon: const Icon(Icons.redo),
                                  label: const Text('STEP'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E5FF),
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _startDebug,
                                  icon: const Icon(Icons.bug_report),
                                  label: const Text('DEBUG'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4B4B64),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => _runCode(lesson),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('RUN CODE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _analyzeCode() async {
    setState(() {
      _isAnalyzing = true;
      _tutorHints = [];
    });

    // Simulate network delay for "AI" feel
    await Future.delayed(const Duration(milliseconds: 1500));

    final hints = ref.read(aiTutorRepositoryProvider).analyzeCode(_currentCode);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _tutorHints = hints;
      });
    }
  }

  void _nextStep() {
    setState(() {
      if (_currentStepIndex < _debugSteps.length - 1) {
        _currentStepIndex++;
      } else {
        _isDebugging = false;
        _currentStepIndex = -1;
        _feedbackMessage = 'DEBUGGING: Finished execution.';
      }
    });
  }

  void _runCode(Lesson lesson) {
    // Simple mock validation logic
    // In reality, this would send code to a sandbox or use a more robust matcher
    setState(() {
      if (_currentCode.contains('print("I am a Coder")') ||
          _currentCode.contains("print('I am a Coder')")) {
        _isSuccess = true;
        _feedbackMessage = 'SUCCESS! You cast the spell correctly.';

        ref.read(adaptiveDifficultyProvider.notifier).recordSuccess();

        // Check for badge unlock
        final badgeRepo = ref.read(badgeRepositoryProvider.notifier);
        // Mock: Unlock 'python_pathfinder' on success
        if (!ref
            .read(badgeRepositoryProvider)
            .any((b) => b.id == 'python_pathfinder' && b.isUnlocked)) {
          badgeRepo.unlockBadge('python_pathfinder');
          final badge = ref
              .read(badgeRepositoryProvider)
              .firstWhere((b) => b.id == 'python_pathfinder');
          _showBadgeNotification(badge);
        }

        // Update Quest Progress
        ref
            .read(questRepositoryProvider.notifier)
            .incrementProgress(QuestType.lessonCompletion);

        // Save to Snippet History (Phase 2 Requirement)
        final userId = ref.read(odysseyUserIdProvider);
        if (userId != null) {
          final history = SnippetHistory(
            userId: userId,
            lessonId: widget.lessonId,
            codeSnippet: _currentCode,
            isPassing: true,
          );
          ref.read(historyRepositoryProvider).saveSnippet(history);
        }
      } else {
        _isSuccess = false;
        _feedbackMessage = 'Oops! The output didn\'t match. Try again.';
        ref.read(adaptiveDifficultyProvider.notifier).recordFailure();

        // Save failed attempt too (optional, but good for tracking)
        final userId = ref.read(odysseyUserIdProvider);
        if (userId != null) {
          final history = SnippetHistory(
            userId: userId,
            lessonId: widget.lessonId,
            codeSnippet: _currentCode,
            isPassing: false,
          );
          ref.read(historyRepositoryProvider).saveSnippet(history);
        }
        // Auto-show tutor if failed?
        // _showTutor = true;
        // _analyzeCode();
      }
    });
  }

  void _showBadgeNotification(dynamic badge) {
    showDialog(
      context: context,
      builder: (context) => BadgeNotification(
        badge: badge,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _startDebug() {
    final debugger = ref.read(debuggerRepositoryProvider);
    final steps = debugger.parseAndSimulate(_currentCode);

    setState(() {
      _debugSteps = steps;
      _currentStepIndex = 0;
      _isDebugging = true;
      _feedbackMessage = 'DEBUGGING: Step through the execution.';
    });
  }
}
