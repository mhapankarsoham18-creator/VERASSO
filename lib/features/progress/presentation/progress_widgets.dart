import 'package:flutter/material.dart';

import '../services/progress_tracking_service.dart';

/// Achievement Badge Widget
/// Widget that displays an achievement badge.
class AchievementBadge extends StatelessWidget {
  /// The achievement data to display.
  final AchievementData achievement;

  /// Whether to display a large version of the badge.
  final bool isLarge;

  /// Creates an [AchievementBadge].
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 80.0 : 60.0;

    return Tooltip(
      message: achievement.name,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade600,
                  Colors.orange.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: achievement.iconUrl != null
                ? Image.network(
                    achievement.iconUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 24,
                        color: Colors.white24),
                  )
                : Center(
                    child: Text(
                      '🏆',
                      style: TextStyle(fontSize: size * 0.5),
                    ),
                  ),
          ),
          if (isLarge) ...[
            const SizedBox(height: 8),
            Text(
              achievement.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Progress Bar Widget with animated filling
/// Progress Bar Widget with animated filling.
class AnimatedProgressBar extends StatefulWidget {
  /// The current progress value (0.0 to 1.0).
  final double progress;

  /// The label to display above the progress bar.
  final String label;

  /// The background color of the progress bar track.
  final Color backgroundColor;

  /// The color of the progress bar fill.
  final Color progressColor;

  /// The height of the progress bar.
  final double height;

  /// Optional text to display trailing the label.
  final String? trailingText;

  /// Creates an [AnimatedProgressBar].
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.label,
    this.backgroundColor = const Color(0xFF2A2A3E),
    this.progressColor = const Color(0xFF00D4FF),
    this.height = 8,
    this.trailingText,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

/// Leaderboard Entry Widget
/// Widget representing a single entry in the leaderboard.
class LeaderboardEntry extends StatelessWidget {
  /// The leaderboard entry data.
  final Map<String, dynamic> entry;

  /// The rank index of the user.
  final int index;

  /// Whether this entry corresponds to the current user.
  final bool isCurrentUser;

  /// Creates a [LeaderboardEntry].
  const LeaderboardEntry({
    super.key,
    required this.entry,
    required this.index,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final rank = entry['rank'] as int;
    final username = entry['username'] as String? ?? 'Unknown';
    final points = entry['total_points'] as int? ?? 0;
    final level = entry['current_level'] as int? ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.cyan.shade900.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: isCurrentUser
              ? Colors.cyan.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: rank <= 3
                    ? [Colors.amber.shade600, Colors.orange.shade600]
                    : [Colors.purple.shade600, Colors.blue.shade600],
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level $level',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'points',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Level Badge Widget
/// Widget that displays the user's current level and XP progress.
class LevelBadge extends StatelessWidget {
  /// The current user level.
  final int level;

  /// The title associated with the current level.
  final String title;

  /// The current XP points within the level.
  final int currentXp;

  /// The XP required to reach the next level.
  final int xpToNextLevel;

  /// Creates a [LevelBadge].
  const LevelBadge({
    super.key,
    required this.level,
    required this.title,
    required this.currentXp,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final levelProgress =
        (currentXp.toDouble() / xpToNextLevel.toDouble()).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900,
            Colors.purple.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Level circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.shade400,
                  Colors.blue.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    level.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 150,
            child: AnimatedProgressBar(
              progress: levelProgress,
              label: 'Level Progress',
              height: 6,
              trailingText: '$currentXp / $xpToNextLevel XP',
            ),
          ),
        ],
      ),
    );
  }
}

/// Milestone Card Widget
/// Widget that displays a milestone's progress and status.
class MilestoneCard extends StatelessWidget {
  /// The milestone data to display.
  final MilestoneData milestone;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Creates a [MilestoneCard].
  const MilestoneCard({
    super.key,
    required this.milestone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: milestone.isCompleted
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: milestone.isCompleted
                ? Colors.green.shade400.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    milestone.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (milestone.isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '✓ Done',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (milestone.description != null)
              Text(
                milestone.description!,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            AnimatedProgressBar(
              progress: milestone.progressPercentage / 100,
              label: '${milestone.currentValue} / ${milestone.targetValue}',
              height: 6,
              trailingText:
                  '${milestone.progressPercentage.toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 8),
            Text(
              '+${milestone.rewardPoints} XP',
              style: TextStyle(
                color: Colors.yellow.shade400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress Statistics Widget
/// Widget that displays a summary of user progress statistics.
class ProgressStatistics extends StatelessWidget {
  /// The user progress data.
  final UserProgressData progress;

  /// Creates a [ProgressStatistics].
  const ProgressStatistics({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _StatRow(
            label: 'Posts',
            value: progress.totalPosts.toString(),
            icon: '📝',
          ),
          const Divider(color: Colors.white12, height: 12),
          _StatRow(
            label: 'Comments',
            value: progress.totalComments.toString(),
            icon: '💬',
          ),
          const Divider(color: Colors.white12, height: 12),
          _StatRow(
            label: 'Likes Received',
            value: progress.totalLikesReceived.toString(),
            icon: '❤️',
          ),
          const Divider(color: Colors.white12, height: 12),
          _StatRow(
            label: 'Followers',
            value: progress.totalFollowersGained.toString(),
            icon: '👥',
          ),
          const Divider(color: Colors.white12, height: 12),
          _StatRow(
            label: 'Login Streak',
            value: '${progress.loginStreak} days',
            icon: '🔥',
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.trailingText != null)
              Text(
                widget.trailingText!,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.backgroundColor,
                            widget.backgroundColor.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor: _animation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.progressColor,
                              widget.progressColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation =
          Tween<double>(begin: _animation.value, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
