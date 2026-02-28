import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../badge/domain/badge_model.dart';

/// Provider for the [BadgeRepository] instance.
final badgeRepositoryProvider = NotifierProvider<BadgeRepository, List<Badge>>(
  BadgeRepository.new,
);

/// Repository responsible for managing the collection of earned badges.
class BadgeRepository extends Notifier<List<Badge>> {
  @override
  List<Badge> build() {
    return [
      const Badge(
        id: 'python_pathfinder',
        name: 'Python Pathfinder',
        description: 'Completed your first Python lesson.',
        iconData: Icons.emoji_nature,
      ),
      const Badge(
        id: 'bug_squasher',
        name: 'Bug Squasher',
        description: 'Fixed 5 errors in your code.',
        iconData: Icons.pest_control,
      ),
      const Badge(
        id: 'streak_master',
        name: 'Streak Master',
        description: 'Coded for 3 days in a row.',
        iconData: Icons.local_fire_department,
      ),
    ];
  }

  /// Unlocks a badge by its [badgeId] and records the current timestamp.
  void unlockBadge(String badgeId) {
    state = [
      for (final badge in state)
        if (badge.id == badgeId && !badge.isUnlocked)
          badge.copyWith(isUnlocked: true, unlockedAt: DateTime.now())
        else
          badge,
    ];
  }
}
