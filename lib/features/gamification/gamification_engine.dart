import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import 'data/leaderboard_entry_model.dart';

/// Database instance getter pointing to Supabase.
SupabaseClient get database => Supabase.instance.client;

/// Adds XP to a user by upserting into the `user_xp` table.
Future<void> addXP(String userId, int xp) async {
  try {
    // Fetch current XP, then upsert with incremented value
    await database.rpc(
      'record_activity_v2',
      params: {
        'p_activity_name': 'manual_xp_award',
        'p_metadata': {'xp': xp},
      },
    );
  } catch (e) {
    AppLogger.error('Failed to add XP for user $userId', error: e);
  }
}

/// Awards a badge to a user by inserting into the `user_badges` table.
/// Uses upsert with conflict on (user_id, badge_id) to prevent duplicates.
Future<void> awardBadge(String userId, String badgeId) async {
  try {
    await database.from('user_badges').upsert(
      {
        'user_id': userId,
        'badge_id': badgeId,
        'earned_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,badge_id',
    );
  } catch (e) {
    AppLogger.error('Failed to award badge $badgeId to $userId', error: e);
  }
}

/// Awards XP to a user. Delegates to [addXP].
Future<void> awardXP(String userId, int xp) async => addXP(userId, xp);

/// Fetches user stats for gamification from the `profiles` table,
/// joined with `user_xp` and `user_badges`.
Future<Map<String, dynamic>?> fetchUserStats(String userId) async {
  try {
    final response = await database
        .from('user_stats')
        .select(
            '*, profiles:user_id(username, avatar_url), user_badges(badge_id)')
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  } catch (e) {
    AppLogger.error('Failed to fetch user stats for $userId', error: e);
    return null;
  }
}

/// Sends a gamification notification by inserting into the `notifications` table.
Future<void> sendNotification(String userId, String title, String body) async {
  try {
    await database.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    AppLogger.error('Failed to send notification to $userId', error: e);
  }
}

/// Checks if a user has already earned a specific badge.
Future<bool> userHasBadge(String userId, String badgeId) async {
  try {
    final response = await database
        .from('user_badges')
        .select('id')
        .eq('user_id', userId)
        .eq('badge_id', badgeId)
        .maybeSingle();
    return response != null;
  } catch (e) {
    AppLogger.error('Failed to check badge $badgeId for $userId', error: e);
    return false;
  }
}

/// Definition for a gamification badge.
class BadgeDefinition {
  /// The unique ID of the badge.
  final String id;

  /// The human-readable title of the badge.
  final String title;

  /// A detailed description of the badge.
  final String description;

  /// Path to the badge's icon asset.
  final String icon;

  /// The function that defines the requirements for this badge.
  final Function(dynamic) requirement;

  /// The XP reward granted when this badge is earned.
  final int xpReward;

  /// Creates a [BadgeDefinition].
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.xpReward,
  });
}

/// System for managing and awarding badges.
class BadgeSystem {
  /// Map of all available badge definitions.
  static final Map<String, BadgeDefinition> badges = {
    'novice_coder': const BadgeDefinition(
      id: 'novice_coder',
      title: 'Novice Coder',
      description: 'Complete your first lesson',
      icon: 'assets/badges/novice.png',
      requirement: _requirementNovice,
      xpReward: 20,
    ),
    'python_padawan': const BadgeDefinition(
      id: 'python_padawan',
      title: 'Python Padawan',
      description: 'Complete Module 1: Python Basics',
      icon: 'assets/badges/padawan.png',
      requirement: _requirementPythonPadawan,
      xpReward: 50,
    ),
    'function_master': const BadgeDefinition(
      id: 'function_master',
      title: 'Function Master',
      description: 'Complete Module 2: Functions',
      icon: 'assets/badges/function.png',
      requirement: _requirementFunctionMaster,
      xpReward: 50,
    ),
    'challenge_champion': const BadgeDefinition(
      id: 'challenge_champion',
      title: 'Challenge Champion',
      description: 'Solve 30 challenges',
      icon: 'assets/badges/champion.png',
      requirement: _requirementChallengeChampion,
      xpReward: 150,
    ),
    'codemaster': const BadgeDefinition(
      id: 'codemaster',
      title: 'Codemaster',
      description: 'Complete entire Phase 11',
      icon: 'assets/badges/codemaster.png',
      requirement: _requirementCodemaster,
      xpReward: 200,
    ),
  };

  /// Checks and awards badges for a user.
  static Future<void> checkAndAwardBadges(String userId) async {
    final user = await fetchUserStats(userId);
    if (user == null) return;

    for (final badgeId in badges.keys) {
      final badge = badges[badgeId]!;
      final hasEarned = await userHasBadge(userId, badgeId);
      if (!hasEarned && badge.requirement(user)) {
        await awardBadge(userId, badgeId);
        await awardXP(userId, badge.xpReward);
        await sendNotification(
          userId,
          'Badge Earned!',
          'You unlocked "${badge.title}"',
        );
      }
    }
  }

  static bool _requirementChallengeChampion(dynamic user) =>
      (user['challenges_solved'] as int? ?? 0) >= 30;

  static bool _requirementCodemaster(dynamic user) {
    final modules = user['modules_completed'] as List? ?? [];
    final challenges = user['challenges_solved'] as int? ?? 0;
    final quizzes = user['quizzes_completed'] as int? ?? 0;
    return modules.length == 8 && challenges == 61 && quizzes >= 8;
  }

  static bool _requirementFunctionMaster(dynamic user) {
    final modules = user['modules_completed'] as List? ?? [];
    return modules.contains(2);
  }

  static bool _requirementNovice(dynamic user) =>
      (user['lessons_completed'] as int? ?? 0) >= 1;

  static bool _requirementPythonPadawan(dynamic user) {
    final modules = user['modules_completed'] as List? ?? [];
    return modules.contains(1);
  }
}

/// Engine for leaderboard calculations.
class LeaderboardEngine {
  /// Calculates the tier based on XP.
  static String calculateTier(int totalXP) {
    if (totalXP < 1000) return 'Bronze';
    if (totalXP < 5000) return 'Silver';
    if (totalXP < 10000) return 'Gold';
    return 'Platinum';
  }

  /// Overall rankings (all-time)
  static Future<List<LeaderboardEntry>> getOverallLeaderboard() async {
    try {
      final response = await database.rpc('get_overall_leaderboard').select();
      final dataList = response as List<dynamic>;
      return dataList
          .map((data) => LeaderboardEntry(
                userId: data['user_id'] as String,
                username: data['username'] as String,
                avatarUrl: data['avatar_url'] as String? ?? '',
                score: (data['score'] as num).toInt(),
                rank: (data['rank'] as num).toInt(),
              ))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get overall leaderboard', error: e);
      return [];
    }
  }

  /// Weekly rankings (refreshed every Sunday)
  static Future<List<LeaderboardEntry>> getWeeklyLeaderboard() async {
    try {
      final response = await database.rpc('get_weekly_leaderboard').select();
      final dataList = response as List<dynamic>;
      return dataList
          .map((data) => LeaderboardEntry(
                userId: data['user_id'] as String,
                username: data['username'] as String,
                avatarUrl: data['avatar_url'] as String? ?? '',
                score: (data['score'] as num).toInt(),
                rank: (data['rank'] as num).toInt(),
              ))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get weekly leaderboard', error: e);
      return [];
    }
  }

  /// Refreshes the leaderboard cache by invoking the Supabase RPC.
  /// Should be called after score changes or on a weekly schedule.
  static Future<void> refreshLeaderboard() async {
    try {
      await database.rpc('refresh_leaderboard_cache');
    } catch (e) {
      // Graceful degradation if RPC not available
      AppLogger.debug('Leaderboard refresh skipped');
    }
  }
}

// Redundant LeaderboardEntry removed, using the one from leaderboard_entry_model.dart

/// System for tracking user streaks.
class StreakSystem {
  /// Awards a bonus for maintaining a streak.
  static Future<void> awardStreakBonus(String userId, int streak) async {
    if (streak % 5 == 0) {
      final xpBonus = 25;
      await addXP(userId, xpBonus);
      if (streak == 30) {
        await awardBadge(userId, 'weekend_warrior');
      }
    }
  }

  /// Calculates the current streak for a user.
  static Future<int> calculateStreak(String userId) async {
    try {
      final response = await database
          .from('activities')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      final List<dynamic> data = response;
      if (data.isEmpty) return 0;

      final activities = data
          .map((e) => DateTime.parse(e['created_at'] as String).toLocal())
          .toList();

      int streak = 0;
      DateTime expectedDate = DateTime.now();

      for (final activityDate in activities) {
        if (activityDate.year == expectedDate.year &&
            activityDate.month == expectedDate.month &&
            activityDate.day == expectedDate.day) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else if (activityDate.isBefore(expectedDate)) {
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.error('Failed to calculate streak', error: e);
      return 0;
    }
  }
}

/// Definition of a user tier.
class TierDefinition {
  /// The name of the tier.
  final String name;

  /// Minimum XP required for this tier.
  final int minXP;

  /// Maximum XP allowed for this tier.
  final int maxXP;

  /// Primary color associated with this tier.
  final Color color;

  /// Icon asset path for this tier.
  final String icon;

  /// Creates a [TierDefinition].
  const TierDefinition({
    required this.name,
    required this.minXP,
    required this.maxXP,
    required this.color,
    required this.icon,
  });
}

/// System for managing user tiers.
class TierSystem {
  /// Map of all available tier definitions.
  static const Map<String, TierDefinition> tiers = {
    'bronze': TierDefinition(
      name: 'Bronze',
      minXP: 0,
      maxXP: 999,
      color: Color(0xFFCD7F32),
      icon: 'assets/tiers/bronze.png',
    ),
    'silver': TierDefinition(
      name: 'Silver',
      minXP: 1000,
      maxXP: 4999,
      color: Color(0xFFC0C0C0),
      icon: 'assets/tiers/silver.png',
    ),
    'gold': TierDefinition(
      name: 'Gold',
      minXP: 5000,
      maxXP: 9999,
      color: Color(0xFFFFD700),
      icon: 'assets/tiers/gold.png',
    ),
    'platinum': TierDefinition(
      name: 'Platinum',
      minXP: 10000,
      maxXP: 999999,
      color: Color(0xFFE5E4E2),
      icon: 'assets/tiers/platinum.png',
    ),
  };

  /// Map of feature keys to minimum required XP.
  static const Map<String, int> featureRequirements = {
    'create_guild': 1000, // Silver
    'advanced_analytics': 5000, // Gold
    'custom_avatar_frame': 10000, // Platinum
    'premium_themes': 5000, // Gold
  };

  /// Calculates the progress percentage within a tier.
  static int getProgressPercentage(int currentXP) {
    final tier = getTierForXP(currentXP);
    final tierDef = tiers[tier]!;

    final minXP = tierDef.minXP;
    final maxXP = tierDef.maxXP;
    final progress = currentXP - minXP;
    final range = maxXP - minXP + 1;

    return ((progress / range) * 100).toInt().clamp(0, 100);
  }

  /// Returns the tier key for a given XP.
  static String getTierForXP(int xp) {
    if (xp < 1000) return 'bronze';
    if (xp < 5000) return 'silver';
    if (xp < 10000) return 'gold';
    return 'platinum';
  }

  /// Checks if a user has unlocked a specific feature based on their XP.
  static bool hasFeatureUnlocked(int currentXP, String featureKey) {
    if (!featureRequirements.containsKey(featureKey)) return true;
    return currentXP >= featureRequirements[featureKey]!;
  }
}

/// Engine for calculating and awarding XP for user activities.
class XPRewardEngine {
  /// Map of XP rewards for various user activities.
  static const Map<String, int> activityRewards = {
    // Lessons
    'lesson_complete': 5,
    'module_complete': 50,

    // Challenges
    'challenge_easy': 10,
    'challenge_medium': 25,
    'challenge_hard': 50,
    'challenge_expert': 100,

    // Quizzes
    'quiz_70_79': 5,
    'quiz_80_89': 8,
    'quiz_90_99': 10,
    'quiz_100': 15,

    // Achievements
    'first_lesson': 20,
    'streak_5day': 25,
    'leaderboard_top10': 75,
    'challenge_solved_30': 150,
    'all_challenges_solved': 200,
  };

  /// Map of XP costs for hints.
  static const Map<String, int> hintCost = {
    'hint_used': -2,
  };

  /// Updates user XP in a transaction.
  static Future<void> addUserXP(String userId, int xpGained) async {
    await addXP(userId, xpGained);
  }

  /// Calculates XP for a given activity type.
  static int calculateActivityXP(
    String activityType, {
    int? quizScore,
    int? challengesDone,
  }) {
    if (activityType == 'quiz') {
      if (quizScore != null && quizScore >= 100) {
        return activityRewards['quiz_100']!;
      }
      if (quizScore != null && quizScore >= 90) {
        return activityRewards['quiz_90_99']!;
      }
      if (quizScore != null && quizScore >= 80) {
        return activityRewards['quiz_80_89']!;
      }
      if (quizScore != null && quizScore >= 70) {
        return activityRewards['quiz_70_79']!;
      }
      return 0;
    }
    return activityRewards[activityType] ?? 0;
  }

  /// Gets the current global XP multiplier (e.g., weekends).
  static double getGlobalMultiplier() {
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return 1.5;
    }
    return 1.0;
  }
}
