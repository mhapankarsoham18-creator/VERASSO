import '../data/leaderboard_entry_model.dart';
import '../models/badge_model.dart';

/// Service responsible for gamification logic, including XP calculation and badge unlocking.
class GamificationService {
  /// Calculate level from total XP
  static int calculateLevel(int totalXP) {
    // Simple formula: level = sqrt(XP / 100)
    return (totalXP / 100).floor() + 1;
  }

  /// Calculate XP earned for completing a simulation
  static int calculateSimulationXP(String simulationId) {
    // Base XP per simulation
    return 100;
  }

  /// Check and unlock badges based on user stats
  static List<Badge> checkUnlockedBadges(UserStats stats) {
    final newlyUnlocked = <Badge>[];

    for (final badge in BadgeDefinitions.availableBadges.values) {
      // Skip if already unlocked
      if (stats.unlockedBadges.contains(badge.id)) continue;

      bool shouldUnlock = false;

      switch (badge.id) {
        case 'physics_master':
          shouldUnlock = (stats.subjectProgress['Physics'] ?? 0) >= 12;
          break;
        case 'chemistry_expert':
          shouldUnlock = (stats.subjectProgress['Chemistry'] ?? 0) >= 6;
          break;
        case 'biology_genius':
          shouldUnlock = (stats.subjectProgress['Biology'] ?? 0) >= 11;
          break;
        case 'explorer':
          final totalSims =
              stats.subjectProgress.values.fold(0, (a, b) => a + b);
          shouldUnlock = totalSims >= 29;
          break;
        case 'stargazer':
          shouldUnlock = (stats.subjectProgress['Astronomy'] ?? 0) >= 1;
          break;
        case 'molecule_builder':
          shouldUnlock = (stats.subjectProgress['Molecular'] ?? 0) >= 10;
          break;
        case 'streak_master':
          shouldUnlock = stats.currentStreak >= 30;
          break;
        case 'first_steps':
          final totalSims =
              stats.subjectProgress.values.fold(0, (a, b) => a + b);
          shouldUnlock = totalSims >= 1;
          break;
      }

      if (shouldUnlock) {
        newlyUnlocked.add(badge);
      }
    }

    return newlyUnlocked;
  }

  /// Get badge color based on rarity
  static String getBadgeColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return '#9E9E9E'; // Gray
      case BadgeRarity.rare:
        return '#2196F3'; // Blue
      case BadgeRarity.epic:
        return '#9C27B0'; // Purple
      case BadgeRarity.legendary:
        return '#FF9800'; // Orange
    }
  }

  /// Get leaderboard rankings
  static List<LeaderboardEntry> getLeaderboard(List<UserStats> allUsers) {
    final entries = allUsers
        .map((stats) => LeaderboardEntry(
              userId: stats.userId,
              username: stats.displayName,
              totalXP: stats.totalXP,
              level: stats.level,
              badges: stats.unlockedBadges.length,
              rank: 0,
            ))
        .toList();

    entries.sort((a, b) => (b.totalXP ?? 0).compareTo(a.totalXP ?? 0));

    // Add rankings
    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }

    return entries;
  }

  /// Update streak based on last active date
  static Map<String, int> updateStreak(DateTime lastActive, int currentStreak) {
    final now = DateTime.now();
    final daysSinceActive = now.difference(lastActive).inDays;

    if (daysSinceActive == 0) {
      // Same day, no change
      return {'currentStreak': currentStreak, 'broken': 0};
    } else if (daysSinceActive == 1) {
      // Next day, increment
      return {'currentStreak': currentStreak + 1, 'broken': 0};
    } else {
      // Streak broken
      return {'currentStreak': 0, 'broken': 1};
    }
  }
}

// Redundant LeaderboardEntry removed, using the one from leaderboard_entry_model.dart
