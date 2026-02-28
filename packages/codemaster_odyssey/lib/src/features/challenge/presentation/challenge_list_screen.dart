import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../challenge/data/challenge_repository.dart';
import '../../challenge/domain/challenge_model.dart';
import 'challenge_screen.dart';

/// Screen that displays a grid of available coding challenges.
class ChallengeListScreen extends ConsumerWidget {
  /// Creates a [ChallengeListScreen] widget.
  const ChallengeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengeRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text(
          'CHALLENGE LIBRARY',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF2D2D44),
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Adjust for screen size in real app
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return _ChallengeCard(challenge: challenge);
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    Color difficultyColor;
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        difficultyColor = Colors.greenAccent;
        break;
      case ChallengeDifficulty.medium:
        difficultyColor = Colors.orangeAccent;
        break;
      case ChallengeDifficulty.hard:
        difficultyColor = Colors.redAccent;
        break;
      case ChallengeDifficulty.legendary:
        difficultyColor = Colors.purpleAccent;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChallengeScreen(challengeId: challenge.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: challenge.isCompleted
                ? const Color(0xFFFFD700)
                : Colors.white10,
            width: challenge.isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: difficultyColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    challenge.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: difficultyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (challenge.isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              challenge.title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${challenge.xpReward} XP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ).animate().scale(delay: 100.ms),
    );
  }
}
