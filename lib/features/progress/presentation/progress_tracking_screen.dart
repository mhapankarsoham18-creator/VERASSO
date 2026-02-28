import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../services/progress_tracking_service.dart';
import 'progress_widgets.dart';

/// Screen for viewing user progress, achievements, and milestones.
class ProgressTrackingScreen extends ConsumerWidget {
  /// Creates a [ProgressTrackingScreen].
  const ProgressTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (authStateData) {
        final userId = authStateData?.id;
        if (userId == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view progress')),
          );
        }
        return _ProgressContent(userId: userId);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  final List<AchievementData> achievements;

  const _AchievementsTab({required this.achievements});

  @override
  Widget build(BuildContext context) {
    // All achievements have earned_at as non-nullable
    final unlocked = achievements;
    final locked = <AchievementData>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unlocked.isNotEmpty) ...[
            Text(
              'Unlocked (${unlocked.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: unlocked.map((a) {
                return AchievementBadge(
                  achievement: a,
                  isLarge: true,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (locked.isNotEmpty) ...[
            Text(
              'Locked (${locked.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: locked.map((a) {
                return Opacity(
                  opacity: 0.5,
                  child: AchievementBadge(
                    achievement: a,
                    isLarge: true,
                  ),
                );
              }).toList(),
            ),
          ],
          if (achievements.isEmpty)
            const Center(child: Text('No achievements yet')),
        ],
      ),
    );
  }
}

class _MilestonesTab extends ConsumerWidget {
  final List<MilestoneData> milestones;
  final String userId;

  const _MilestonesTab({
    required this.milestones,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = milestones.where((m) => !m.isCompleted).toList();
    final completed = milestones.where((m) => m.isCompleted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.isNotEmpty) ...[
            Text(
              'Active Milestones (${active.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...active.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MilestoneCard(milestone: m),
                )),
            const SizedBox(height: 24),
          ],
          if (completed.isNotEmpty) ...[
            Text(
              'Completed Milestones (${completed.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...completed.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MilestoneCard(milestone: m),
                )),
          ],
          if (milestones.isEmpty)
            const Center(child: Text('No milestones yet')),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final UserProgressData progress;
  final String userId;

  const _OverviewTab({
    required this.progress,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextMilestoneAsync = ref.watch(nextMilestoneProvider(userId));
    final timeToNextLevelAsync = ref.watch(timeToNextLevelProvider(userId));
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final userRankAsync = ref.watch(userRankProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Badge
          Center(
            child: LevelBadge(
              level: progress.currentLevel,
              title: _getLevelTitle(progress.currentLevel),
              currentXp: progress.currentXp,
              xpToNextLevel: progress.xpToNextLevel,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          ProgressStatistics(progress: progress),
          const SizedBox(height: 24),

          // Next Milestone
          Text(
            'Next Milestone',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          nextMilestoneAsync.when(
            data: (milestone) {
              if (milestone == null) {
                return const Text('All milestones completed!');
              }
              return MilestoneCard(milestone: milestone);
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          ),
          const SizedBox(height: 24),

          // Time to Next Level
          Text(
            'Level Progression',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          timeToNextLevelAsync.when(
            data: (duration) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('Estimated time to next level: ',
                        style: TextStyle(color: Colors.white70)),
                    Text(
                      _formatDuration(duration ?? Duration.zero),
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          ),
          const SizedBox(height: 24),

          // Leaderboard Preview
          Text(
            'Top Players',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          leaderboardAsync.when(
            data: (entries) {
              return Column(
                children: entries.take(5).map((entry) {
                  final isCurrentUser = entry['user_id'] == userId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LeaderboardEntry(
                      entry: entry,
                      index: entries.indexOf(entry),
                      isCurrentUser: isCurrentUser,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to full leaderboard
              },
              child: const Text('View Full Leaderboard'),
            ),
          ),
          const SizedBox(height: 24),

          // Your Rank
          userRankAsync.when(
            data: (rank) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.cyan.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Rank',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} days';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes';
    } else {
      return 'Very soon!';
    }
  }

  String _getLevelTitle(int level) {
    const titles = [
      'Novice',
      'Apprentice',
      'Intermediate',
      'Advanced',
      'Expert',
      'Master',
      'Grandmaster',
    ];
    return titles[level - 1];
  }
}

class _ProgressContent extends ConsumerWidget {
  final String userId;

  const _ProgressContent({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressStreamProvider(userId));
    final milestonesAsync = ref.watch(userMilestonesProvider(userId));
    final achievementsAsync = ref.watch(userAchievementsProvider(userId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Progress'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Milestones'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Overview Tab
            progressAsync.when(
              data: (progress) {
                if (progress == null) {
                  return const Center(child: Text('No progress data'));
                }
                return _OverviewTab(progress: progress, userId: userId);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            // Milestones Tab
            milestonesAsync.when(
              data: (milestones) => _MilestonesTab(
                milestones: milestones,
                userId: userId,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            // Achievements Tab
            achievementsAsync.when(
              data: (achievements) => _AchievementsTab(
                achievements: achievements,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
