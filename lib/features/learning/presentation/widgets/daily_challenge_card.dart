import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/shimmers/dashboard_skeleton.dart';
import 'package:verasso/features/learning/data/collaboration_models.dart';
import 'package:verasso/features/learning/data/collaboration_repository.dart';

/// Provider that fetches active daily challenges.
final activeChallengesProvider = FutureProvider<List<DailyChallenge>>((ref) {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getActiveChallenges();
});

/// Displays the current daily challenge with a complete button.
class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(activeChallengesProvider).when(
      data: (challenges) {
        if (challenges.isEmpty) return const SizedBox.shrink();
        final challenge = challenges.first;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Semantics(
            label:
                'Daily Challenge: ${challenge.subject}. ${challenge.title}. ${challenge.content}',
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              color: Colors.amber.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.zap,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY CHALLENGE - ${challenge.subject}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await ref
                            .read(collaborationRepositoryProvider)
                            .completeChallenge(
                              challenge.id,
                              challenge.rewardPoints,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Challenge Complete! +${challenge.rewardPoints} Karma',
                              ),
                            ),
                          );
                          ref.invalidate(activeChallengesProvider);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Complete & Earn 20 Karma'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const DashboardSkeleton(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
