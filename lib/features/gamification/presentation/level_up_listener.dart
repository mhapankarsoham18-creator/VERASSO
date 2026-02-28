import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/animations/level_milestone_animation.dart';
import 'user_stats_controller.dart';

/// Listens for level changes and shows milestone animations
class LevelUpListener extends ConsumerStatefulWidget {
  /// The widget tree that this listener wraps.
  final Widget child;

  /// Creates a [LevelUpListener] instance.
  const LevelUpListener({super.key, required this.child});

  @override
  ConsumerState<LevelUpListener> createState() => _LevelUpListenerState();
}

class _LevelUpListenerState extends ConsumerState<LevelUpListener> {
  int? _previousLevel;

  @override
  Widget build(BuildContext context) {
    // Listen to changes in user stats
    ref.listen<UserStatsState>(userStatsProvider, (previous, next) {
      if (next.stats != null) {
        final currentLevel = next.stats!.level;

        // Initialize previous level if first load
        if (_previousLevel == null) {
          _previousLevel = currentLevel;
          return;
        }

        // Check for level up
        if (currentLevel > _previousLevel!) {
          // Check for milestone (every 10 levels)
          if (currentLevel % 10 == 0) {
            _showLevelUpDialog(context, currentLevel);
          } else {
            // Optional: Simple toast for regular levels
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Level Up! You are now level $currentLevel'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          _previousLevel = currentLevel;
        }
      }
    });

    return widget.child;
  }

  void _showLevelUpDialog(BuildContext context, int level) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: LevelMilestoneAnimation(
            level: level,
            onComplete: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
