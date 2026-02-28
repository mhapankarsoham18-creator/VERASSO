import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../ai_tutor/data/ai_tutor_repository.dart';
import '../../ai_tutor/domain/tutor_hint_model.dart';
import '../../ai_tutor/presentation/ai_tutor_widget.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../editor/presentation/odyssey_editor.dart';

/// Screen where a user can view details of a specific challenge and submit their solution.
class ChallengeScreen extends ConsumerStatefulWidget {
  /// Unique identifier of the challenge to display.
  final String challengeId;

  /// Creates a [ChallengeScreen] widget.
  const ChallengeScreen({super.key, required this.challengeId});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  String _currentCode = '';
  String _feedbackMessage = '';
  bool _isSuccess = false;

  // AI Tutor State
  List<TutorHint> _tutorHints = [];
  bool _isAnalyzing = false;
  bool _showTutor = false;

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(challengeRepositoryProvider);
    final challenge = challenges.firstWhere((c) => c.id == widget.challengeId);

    if (_currentCode.isEmpty && !challenge.isCompleted) {
      // Only set starter code if not already editing (though rebuilding widget might reset it,
      // for MVP this simple check is okayish if state is preserved)
      // Better: Initialize in initState.
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text(challenge.title),
        backgroundColor: const Color(0xFF2D2D44),
        actions: [
          IconButton(
            icon: Icon(_showTutor ? Icons.close : Icons.psychology),
            onPressed: () {
              setState(() {
                _showTutor = !_showTutor;
              });
            },
            tooltip: 'Ask AI Tutor',
          ),
        ],
      ),
      body: Column(
        children: [
          // Problem Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2D2D44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.description,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Goal: ${challenge.expectedOutput.replaceAll("\n", " -> ")}',
                  style: GoogleFonts.firaCode(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: OdysseyEditor(
                initialCode: _currentCode.isEmpty
                    ? challenge.starterCode
                    : _currentCode,
                onChanged: (value) {
                  _currentCode = value;
                },
              ),
            ),
          ),

          // AI Tutor Helper
          if (_showTutor)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AiTutorWidget(
                hints: _tutorHints,
                isAnalyzing: _isAnalyzing,
                onAnalyze: _analyzeCode,
              ),
            ),

          // Feedback & Controls
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
                textAlign: TextAlign.center,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _runChallenge(challenge.expectedOutput),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFFFD700,
                  ), // Gold for challenges
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'SUBMIT SOLUTION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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

    await Future.delayed(const Duration(milliseconds: 1000));
    final hints = ref.read(aiTutorRepositoryProvider).analyzeCode(_currentCode);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _tutorHints = hints;
      });
    }
  }

  void _runChallenge(String expected) {
    // Mock Validation: simpler than checking exact output for now
    // In real app, we'd run Python in WASM/Backend

    // Very naive check for demo purposes:
    // If usage of print matches lines of expected output?

    // Let's just assume success if code is non-empty and contains "print" for easy demo
    // OR if we want to be tricky, check for specific keywords from the challenge

    setState(() {
      if (_currentCode.trim().isNotEmpty && _currentCode.contains('print')) {
        _isSuccess = true;
        _feedbackMessage = 'Challenge Solved! Reward Claimed.';
        ref
            .read(challengeRepositoryProvider.notifier)
            .completeChallenge(widget.challengeId);
      } else {
        _isSuccess = false;
        _feedbackMessage = 'Output incorrect. Check your logic!';
      }
    });
  }
}
