import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../features/gamification/data/leaderboard_entry_model.dart';

/// Provider for AchievementsService
final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  return AchievementsService(Supabase.instance.client);
});

/// Represents an achievement that can be earned by a user.
class AchievementModel {
  /// Unique identifier for the achievement.
  final String id;

  /// The name of the achievement.
  final String name;

  /// A detailed description of the achievement.
  final String description;

  /// The category the achievement belongs to (e.g., 'learning').
  final String category;

  /// Optional URL to an icon representing the achievement.
  final String? iconUrl;

  /// The type of requirement needed to earn the achievement.
  final String requirementType;

  /// The value associated with the requirement.
  final int requirementValue;

  /// The number of points rewarded upon completion.
  final int pointsReward;

  /// The rarity level of the achievement (e.g., 'legendary').
  final String rarity;

  /// Whether the achievement is currently active and earnable.
  final bool isActive;

  /// Creates an [AchievementModel].
  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.iconUrl,
    required this.requirementType,
    required this.requirementValue,
    required this.pointsReward,
    required this.rarity,
    required this.isActive,
  });

  /// Creates an [AchievementModel] from a JSON map.
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      iconUrl: json['icon_url'],
      requirementType: json['requirement_type'],
      requirementValue: json['requirement_value'],
      pointsReward: json['points_reward'] ?? 0,
      rarity: json['rarity'],
      isActive: json['is_active'] ?? true,
    );
  }

  /// Gets the icon representing the category.
  String get categoryIcon {
    switch (category) {
      case 'learning':
        return '📚';
      case 'building':
        return '🏗️';
      case 'social':
        return '👥';
      case 'engagement':
        return '🔥';
      default:
        return '🏆';
    }
  }

  /// Gets the icon representing the rarity.
  String get rarityIcon {
    switch (rarity) {
      case 'legendary':
        return '💎';
      case 'epic':
        return '🌟';
      case 'rare':
        return '⭐';
      case 'uncommon':
        return '🥈';
      case 'common':
      default:
        return '🥉';
    }
  }
}

/// Service for managing user achievements, progress, and leaderboards.
class AchievementsService {
  final SupabaseClient _supabase;

  /// Creates an [AchievementsService] instance.
  AchievementsService(this._supabase);

  /// Check if user earned any new achievements
  Future<List<AchievementModel>> checkAchievements() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];
      final userId = currentUser.id;

      // Call the check function
      await _supabase.rpc('check_user_achievements', params: {
        'p_user_id': userId,
      });

      // Get newly earned achievements
      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .gte(
              'earned_at',
              DateTime.now()
                  .subtract(const Duration(seconds: 5))
                  .toIso8601String());

      return (response as List)
          .map((json) => AchievementModel.fromJson(json['achievements']))
          .toList();
    } catch (e) {
      AppLogger.error('Error checking achievements', error: e);
      return [];
    }
  }

  /// Get achievement progress for a specific achievement.
  ///
  /// Returns 0 if the user is not authenticated or if an error occurs.
  Future<int> getAchievementProgress(String achievementId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 0;
      final userId = currentUser.id;

      final response = await _supabase
          .from('user_achievements')
          .select('progress')
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      return response?['progress'] ?? 0;
    } catch (e) {
      AppLogger.error('Error getting achievement progress', error: e);
      return 0;
    }
  }

  /// Get achievements by category.
  ///
  /// Throws a [DatabaseException] if the query fails.
  Future<List<AchievementModel>> getAchievementsByCategory(
      String category) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('requirement_value', ascending: true);

      return (response as List)
          .map((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException(
          'Failed to get achievements by category: $e', null, e);
    }
  }

  /// Get achievements by rarity.
  ///
  /// Throws a [DatabaseException] if the query fails.
  Future<List<AchievementModel>> getAchievementsByRarity(String rarity) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('rarity', rarity)
          .eq('is_active', true);

      return (response as List)
          .map((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException(
          'Failed to get achievements by rarity: $e', null, e);
    }
  }

  /// Get all available achievements.
  ///
  /// Throws a [DatabaseException] if the query fails.
  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('is_active', true)
          .order('requirement_value', ascending: true);

      return (response as List)
          .map((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get achievements: $e', null, e);
    }
  }

  /// Get earned achievements only.
  ///
  /// Throws a [DatabaseException] if the query fails.
  Future<List<UserAchievementModel>> getEarnedAchievements() async {
    try {
      final achievements = await getUserAchievements();
      return achievements.where((a) => a.isCompleted).toList();
    } catch (e) {
      throw DatabaseException('Failed to get earned achievements: $e', null, e);
    }
  }

  /// Get global leaderboard.
  ///
  /// Throws a [DatabaseException] if the query fails.
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({
    int limit = 100,
  }) async {
    try {
      final response =
          await _supabase.from('user_leaderboard').select().limit(limit);

      return (response as List)
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get leaderboard: $e', null, e);
    }
  }

  /// Get users around my rank.
  ///
  /// Throws a [DatabaseException] if the query fails.
  Future<List<LeaderboardEntry>> getLeaderboardAroundMe({
    int range = 5,
  }) async {
    try {
      final myRank = await getMyRank();
      final startRank = (myRank - range).clamp(1, double.infinity).toInt();
      final endRank = myRank + range;

      final response = await _supabase
          .from('user_leaderboard')
          .select()
          .gte('rank', startRank)
          .lte('rank', endRank)
          .order('rank', ascending: true);

      return (response as List)
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get nearby leaderboard: $e', null, e);
    }
  }

  /// Get user's rank.
  ///
  /// Returns 0 if not ranked or an error occurs.
  Future<int> getMyRank() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return -1;
      final userId = currentUser.id;

      final response = await _supabase
          .from('user_stats')
          .select('rank')
          .eq('user_id', userId)
          .single();

      return response['rank'] ?? 0;
    } catch (e) {
      AppLogger.error('Error getting my rank', error: e);
      return 0;
    }
  }

  /// Get top performers (top 10).
  Future<List<LeaderboardEntry>> getTopPerformers() async {
    return await getGlobalLeaderboard(limit: 10);
  }

  /// Get user's achievements (earned and in-progress).
  ///
  /// Throws a [DatabaseException] if the query fails.
  Future<List<UserAchievementModel>> getUserAchievements() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];
      final userId = currentUser.id;

      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return (response as List)
          .map((json) => UserAchievementModel.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get user achievements: $e', null, e);
    }
  }
}

// Internal LeaderboardEntryModel removed

/// Represents a user's progress or completion of a specific achievement.
class UserAchievementModel {
  /// Unique identifier for the user-achievement link.
  final String id;

  /// The ID of the user.
  final String userId;

  /// The ID of the achievement.
  final String achievementId;

  /// The date and time when the achievement was earned.
  final DateTime? earnedAt;

  /// The current progress towards the achievement (0 to 100).
  final int progress;

  /// Whether the user has completed the achievement.
  final bool isCompleted;

  /// The underlying achievement details (optional join).
  final AchievementModel? achievement;

  /// Creates a [UserAchievementModel] instance.
  UserAchievementModel({
    required this.id,
    required this.userId,
    required this.achievementId,
    this.earnedAt,
    required this.progress,
    required this.isCompleted,
    this.achievement,
  });

  /// Creates a [UserAchievementModel] from a JSON map.
  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    return UserAchievementModel(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      earnedAt:
          json['earned_at'] != null ? DateTime.parse(json['earned_at']) : null,
      progress: json['progress'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      achievement: json['achievement'] != null
          ? AchievementModel.fromJson(json['achievement'])
          : null,
    );
  }

  /// Gets the progress as a percentage (0.0 to 1.0).
  double get progressPercentage => progress / 100.0;
}
