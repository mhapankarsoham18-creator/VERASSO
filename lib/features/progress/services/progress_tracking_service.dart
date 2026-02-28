import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import '../../gamification/models/badge_model.dart';
import '../../gamification/services/gamification_service.dart';
import '../../notifications/data/notification_service.dart';
import '../../notifications/models/notification_model.dart';

/// Provider for fetching the global leaderboard.
final leaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getLeaderboard();
});

/// Provider for fetching the user's next uncompleted milestone.
final nextMilestoneProvider =
    FutureProvider.family<MilestoneData?, String>((ref, userId) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getNextMilestone(userId);
});

/// Provider for the [ProgressTrackingService] singleton.
final progressTrackingServiceProvider = Provider((ref) {
  return ProgressTrackingService();
});

/// Provider for estimating the time remaining until the user reaches the next level.
final timeToNextLevelProvider =
    FutureProvider.family<Duration?, String>((ref, userId) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.estimateTimeToNextLevel(userId);
});

/// Provider for fetching the list of achievements earned by a user.
final userAchievementsProvider =
    FutureProvider.family<List<AchievementData>, String>((ref, userId) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getUserAchievements(userId);
});

/// Provider for fetching the list of milestones for a user.
final userMilestonesProvider =
    FutureProvider.family<List<MilestoneData>, String>((ref, userId) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getUserMilestones(userId);
});

/// Provider for fetching the user's progress data (detailed).
final userProgressProvider =
    FutureProvider.family<UserProgressData?, String>((ref, userId) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getUserProgress(userId);
});

/// Provider for streaming updates to a user's progress data.
final userProgressStreamProvider =
    StreamProvider.family<UserProgressData?, String>((ref, userId) {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.streamUserProgress(userId);
});

/// Future provider for the current user's progress summary.
final userProgressSummaryProvider =
    FutureProvider<UserProgressModel>((ref) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getUserProgressSummary();
});

/// Provider for fetching the user's current rank on the leaderboard.
final userRankProvider =
    FutureProvider.family<int?, String>((ref, userId) async {
  final service = ref.watch(progressTrackingServiceProvider);
  return service.getUserRank(userId);
});

// --- MODELS ---

/// Represents an achievement earned by a user.
class AchievementData {
  /// Unique identifier for the achievement record.
  final String id;

  /// The ID of the achievement template.
  final String achievementId;

  /// The name of the achievement.
  final String name;

  /// A detailed description of the achievement.
  final String? description;

  /// The URL to the achievement's icon.
  final String? iconUrl;

  /// The number of points awarded for earning this achievement.
  final int pointsAwarded;

  /// The date and time when the achievement was earned.
  final DateTime earnedAt;

  /// Whether the achievement is pinned to the user's profile.
  final bool isPinned;

  /// Creates an [AchievementData] instance.
  AchievementData({
    required this.id,
    required this.achievementId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.pointsAwarded,
    required this.earnedAt,
    required this.isPinned,
  });

  /// Creates an [AchievementData] instance from a JSON map.
  factory AchievementData.fromJson(Map<String, dynamic> json) {
    return AchievementData(
      id: json['id'] ?? '',
      achievementId: json['achievement_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      iconUrl: json['icon_url'],
      pointsAwarded: json['points_awarded'] as int? ?? 0,
      earnedAt: DateTime.parse(
          json['earned_at'] as String? ?? DateTime.now().toIso8601String()),
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }
}

/// Represents a discrete activity performed by a user.
class ActivityModel {
  /// Unique identifier for the activity record.
  final String id;

  /// The ID of the user who performed the activity.
  final String userId;

  /// The type of activity performed (e.g., 'post_created').
  final String activityType;

  /// The category of the activity (e.g., 'social', 'learning').
  final String activityCategory;

  /// The number of points earned from this activity.
  final int pointsEarned;

  /// Additional metadata associated with the activity.
  final Map<String, dynamic> metadata;

  /// The date and time when the activity occurred.
  final DateTime createdAt;

  /// Creates an [ActivityModel] instance.
  ActivityModel({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.activityCategory,
    required this.pointsEarned,
    required this.metadata,
    required this.createdAt,
  });

  /// Creates an [ActivityModel] instance from a JSON map.
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      activityType: json['activity_type'] ?? '',
      activityCategory: json['activity_category'] ?? '',
      pointsEarned: json['points_earned'] ?? 0,
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Represents the progress made by a user on a specific day.
class DailyProgressModel {
  /// Unique identifier for the daily progress record.
  final String id;

  /// The ID of the user.
  final String userId;

  /// The date for this progress record.
  final DateTime date;

  /// Total points earned on this day.
  final int pointsEarned;

  /// Total lessons completed on this day.
  final int lessonsCompleted;

  /// Total time spent studying in minutes on this day.
  final int studyTimeMinutes;

  /// Creates a [DailyProgressModel] instance.
  DailyProgressModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.pointsEarned,
    required this.lessonsCompleted,
    required this.studyTimeMinutes,
  });

  /// Creates a [DailyProgressModel] instance from a JSON map.
  factory DailyProgressModel.fromJson(Map<String, dynamic> json) {
    return DailyProgressModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      date: DateTime.parse(
          json['date'] as String? ?? DateTime.now().toIso8601String()),
      pointsEarned: json['points_earned'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      studyTimeMinutes: json['study_time_minutes'] ?? 0,
    );
  }
}

/// Represents a milestone in the user's progress journey.
class MilestoneData {
  /// Unique identifier for the milestone record.
  final String id;

  /// The type of milestone (e.g., 'lessons_completed').
  final String milestoneType;

  /// The display title of the milestone.
  final String title;

  /// A description of what the milestone represents.
  final String? description;

  /// The target value to reach for completion.
  final int targetValue;

  /// The current value achieved towards the target.
  final int currentValue;

  /// The progress as a percentage (0.0 to 1.0).
  final double progressPercentage;

  /// The point reward for completing the milestone.
  final int rewardPoints;

  /// The badge ID rewarded upon completion, if any.
  final String? rewardBadge;

  /// Whether the milestone has been completed.
  final bool isCompleted;

  /// The date and time when the milestone record was created.
  final DateTime createdAt;

  /// The date and time when the milestone was completed.
  final DateTime? completedAt;

  /// Creates a [MilestoneData] instance.
  MilestoneData({
    required this.id,
    required this.milestoneType,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.progressPercentage,
    required this.rewardPoints,
    required this.rewardBadge,
    required this.isCompleted,
    required this.createdAt,
    required this.completedAt,
  });

  /// Creates a [MilestoneData] instance from a JSON map.
  factory MilestoneData.fromJson(Map<String, dynamic> json) {
    return MilestoneData(
      id: json['id'] ?? '',
      milestoneType: json['milestone_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      targetValue: json['target_value'] as int? ?? 0,
      currentValue: json['current_value'] as int? ?? 0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      rewardPoints: json['reward_points'] as int? ?? 0,
      rewardBadge: json['reward_badge'],
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

/// Service responsible for tracking user progress, milestones, and achievements.
class ProgressTrackingService {
  final SupabaseClient _client;

  /// Creates a [ProgressTrackingService] with an optional [client].
  ProgressTrackingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Awards an achievement to a user.
  Future<void> awardAchievement({
    required String userId,
    required String achievementId,
    required String name,
    required String description,
    required int pointsAwarded,
    String? iconUrl,
  }) async {
    try {
      await _client.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievementId,
        'name': name,
        'description': description,
        'icon_url': iconUrl,
        'points_awarded': pointsAwarded,
        'earned_at': DateTime.now().toIso8601String(),
      });

      // Award points via activity log
      await logActivity(userId: userId, activityType: 'achievement_earned');
    } catch (e, stack) {
      AppLogger.error('Error awarding achievement', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to award achievement: $e');
    }
  }

  /// Checks if a user has met any new milestone requirements and awards them if so.
  Future<void> checkAndAwardMilestones(String userId) async {
    try {
      await _client.rpc(
        'check_and_award_milestones',
        params: {'p_user_id': userId},
      );
    } catch (e, stack) {
      AppLogger.error('Error checking milestones', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Creates a new milestone for a user.
  Future<void> createMilestone({
    required String userId,
    required String milestoneType,
    required String title,
    required String description,
    required int targetValue,
    required int rewardPoints,
    String? rewardBadge,
  }) async {
    try {
      // Get user's progress ID
      final progressResponse = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .single();

      final userProgressId = progressResponse['id'];

      // Create milestone
      await _client.from('progress_milestones').insert({
        'user_progress_id': userProgressId,
        'milestone_type': milestoneType,
        'title': title,
        'description': description,
        'target_value': targetValue,
        'current_value': 0,
        'reward_points': rewardPoints,
        'reward_badge': rewardBadge,
        'is_completed': false,
      });
    } catch (e, stack) {
      AppLogger.error('Error creating milestone', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to create milestone: $e');
    }
  }

  /// Estimates the time remaining until the user reaches the next level.
  Future<Duration?> estimateTimeToNextLevel(String userId) async {
    try {
      final progress = await getUserProgress(userId);
      if (progress == null) return null;

      final daysSinceCreation =
          DateTime.now().difference(progress.createdAt).inDays;
      if (daysSinceCreation == 0) return null;

      final dailyXpRate = progress.currentXp / daysSinceCreation;
      if (dailyXpRate == 0) return null;

      final xpRemaining = progress.xpToNextLevel -
          (progress.currentXp % progress.xpToNextLevel);
      final daysRemaining = xpRemaining / dailyXpRate;

      return Duration(days: daysRemaining.toInt());
    } catch (e, stack) {
      AppLogger.error('Error calculating time to next level', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }

  /// Retrieves the user's daily progress for a specific date.
  Future<Map<String, dynamic>> getDailyProgress(
      String userId, DateTime date) async {
    try {
      final response = await _client
          .from('daily_progress')
          .select()
          .eq('user_id', userId)
          .eq('date', date.toIso8601String().substring(0, 10))
          .single();
      return response;
    } catch (e, stack) {
      AppLogger.error('Error fetching daily progress', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return {};
    }
  }

  /// Retrieves the history of daily progress for a user.
  Future<List<DailyProgressModel>> getDailyProgressHistory({
    String? userId,
    int days = 30,
  }) async {
    try {
      userId ??= _client.auth.currentUser?.id;
      if (userId == null) return [];

      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _client
          .from('daily_progress')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().substring(0, 10))
          .order('date', ascending: true);

      return (response as List)
          .map((json) =>
              DailyProgressModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching daily progress history', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Retrieves the global leaderboard.
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      final response =
          await _client.from('v_leaderboard').select().limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching leaderboard', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Retrieves the next uncompleted milestone for the user.
  Future<MilestoneData?> getNextMilestone(String userId) async {
    try {
      final milestones = await getUserMilestones(userId);
      return milestones.where((m) => !m.isCompleted).firstOrNull;
    } catch (e, stack) {
      AppLogger.error('Error getting next milestone', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }

  /// Retrieves recent activities for a user.
  Future<List<ActivityModel>> getRecentActivities({int limit = 10}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_activity')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching recent activities', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Get list of unlocked badge IDs
  Future<List<String>> getUnlockedBadges(String userId) async {
    try {
      final response = await _client
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', userId);

      return (response as List).map((e) => e['badge_id'] as String).toList();
    } catch (e, stack) {
      AppLogger.warning('Failed to get unlocked badges', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Retrieves the list of achievements earned by the user.
  Future<List<AchievementData>> getUserAchievements(String userId) async {
    try {
      final response = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return (response as List)
          .map((json) => AchievementData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching achievements', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Retrieves the list of milestones for the user.
  Future<List<MilestoneData>> getUserMilestones(String userId) async {
    try {
      final progressResponse = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .single();

      final userProgressId = progressResponse['id'];

      final response = await _client
          .from('progress_milestones')
          .select()
          .eq('user_progress_id', userProgressId)
          .order('is_completed', ascending: true)
          .order('progress_percentage', ascending: false);

      return (response as List)
          .map((json) => MilestoneData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching milestones', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Retrieves the user's progress data (detailed).
  Future<UserProgressData?> getUserProgress(String userId) async {
    try {
      final response = await _client
          .from('v_user_progress_summary')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProgressData.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Error fetching user progress', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }

  /// Retrieves a summary [UserProgressModel].
  Future<UserProgressModel> getUserProgressSummary([String? userId]) async {
    try {
      userId ??= _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('user_progress_summary')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProgressModel.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Failed to get user progress summary', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to get progress: $e');
    }
  }

  /// Retrieves the user's current rank on the leaderboard.
  Future<int?> getUserRank(String userId) async {
    try {
      final response = await _client
          .from('v_leaderboard')
          .select('rank')
          .eq('user_id', userId)
          .single();

      return response['rank'] as int?;
    } catch (e, stack) {
      AppLogger.error('Error fetching user rank', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }

  /// Retrieves the user's weekly learning goals.
  Future<List<WeeklyGoalModel>> getWeeklyGoals([String? userId]) async {
    try {
      userId ??= _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('weekly_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WeeklyGoalModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching weekly goals', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Logs a user activity. Standardized RPC call.
  Future<void> logActivity({
    required String userId,
    required String activityType,
    String? activityCategory,
    String? relatedId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _client.rpc(
        'log_activity_and_award_points',
        params: {
          'p_user_id': userId,
          'p_activity_type': activityType,
          'p_activity_category': activityCategory,
          'p_related_id': relatedId,
          'p_metadata': metadata,
        },
      );

      // Perform secondary checks (gamification hook)
      await _checkGamificationHooks(userId);
    } catch (e, stack) {
      AppLogger.error('Error logging activity', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Logs a study session.
  Future<void> logStudySession(int minutes, String activity) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await logActivity(
      userId: userId,
      activityType: 'study_session',
      activityCategory: 'learning',
      metadata: {'minutes': minutes, 'activity': activity},
    );
  }

  /// Sets a new weekly goal for the user.
  Future<void> setWeeklyGoal({
    required String userId,
    required String goalType,
    required int targetValue,
  }) async {
    try {
      await _client.from('weekly_goals').insert({
        'user_id': userId,
        'goal_type': goalType,
        'target_value': targetValue,
        'current_value': 0,
        'is_completed': false,
      });
    } catch (e, stack) {
      AppLogger.error('Error setting weekly goal', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to set weekly goal: $e');
    }
  }

  /// Streams updates to the user's milestones.
  Stream<List<MilestoneData>> streamUserMilestones(String userId) async* {
    try {
      final progressResponse = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', userId)
          .single();

      final userProgressId = progressResponse['id'];

      yield* _client
          .from('progress_milestones')
          .stream(primaryKey: ['id'])
          .eq('user_progress_id', userProgressId)
          .map((response) {
            return (response as List)
                .map((json) =>
                    MilestoneData.fromJson(json as Map<String, dynamic>))
                .toList();
          });
    } catch (e, stack) {
      AppLogger.error('Error streaming milestones', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Streams updates to the user's progress data.
  Stream<UserProgressData?> streamUserProgress(String userId) {
    return _client
        .from('user_progress')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((response) {
          if (response.isEmpty) return null;
          return UserProgressData.fromJson(response[0]);
        })
        .handleError((e, stack) {
          AppLogger.error('Error streaming progress', error: e);
          SentryService.captureException(e, stackTrace: stack);
        });
  }

  /// Updates the user's daily login streak.
  Future<void> updateLoginStreak(String userId) async {
    try {
      await _client.rpc(
        'update_login_streak',
        params: {'p_user_id': userId},
      );
    } catch (e, stack) {
      AppLogger.error('Error updating login streak', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  Future<void> _checkGamificationHooks(String userId) async {
    try {
      final progress = await getUserProgressSummary(userId);
      final unlockedBadges = await getUnlockedBadges(userId);

      final stats = UserStats(
        userId: userId,
        totalXP: progress.totalPoints,
        level: progress.level,
        unlockedBadges: unlockedBadges,
        currentStreak: progress.streakDays,
        longestStreak: 0,
        subjectProgress: {
          'Physics': progress.circuitsSimulated,
          'Learning': progress.lessonsCompleted,
          'Astronomy': progress.achievementsCount,
        },
        lastActive: progress.lastActive,
      );

      final newBadges = GamificationService.checkUnlockedBadges(stats);

      for (final badge in newBadges) {
        await _client.from('user_badges').insert({
          'user_id': userId,
          'badge_id': badge.id,
          'unlocked_at': DateTime.now().toIso8601String(),
        });

        await NotificationService().createNotification(
          targetUserId: userId,
          type: NotificationType.achievement,
          title: 'Badge Unlocked: ${badge.name}!',
          body: badge.description,
          data: {'badge_id': badge.id},
        );
      }
    } catch (e, stack) {
      AppLogger.warning('Gamification hook processing failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}

/// Represents comprehensive progress data for a user.
class UserProgressData {
  /// The unique identifier for the user.
  final String userId;

  /// Total points earned across all activities.
  final int totalPoints;

  /// The current level of the user.
  final int currentLevel;

  /// The current experience points in the current level.
  final int currentXp;

  /// The total experience points needed to reach the next level.
  final int xpToNextLevel;

  /// The progress towards the next level as a percentage (0.0 to 1.0).
  final double levelProgressPercent;

  /// Total number of posts created by the user.
  final int totalPosts;

  /// Total number of comments made by the user.
  final int totalComments;

  /// Total number of messages sent by the user.
  final int totalMessages;

  /// Total number of likes received by the user.
  final int totalLikesReceived;

  /// Total number of followers gained by the user.
  final int totalFollowersGained;

  /// Current consecutive days the user has logged in.
  final int loginStreak;

  /// The longest login streak achieved by the user.
  final int longestLoginStreak;

  /// The date of the last recorded login.
  final DateTime? lastLoginDate;

  /// Total number of milestones completed by the user.
  final int milestonesCompleted;

  /// Total number of achievements earned by the user.
  final int achievementsEarned;

  /// Total time spent in the app in minutes.
  final int timeSpentMinutes;

  /// The date the user's progress record was created.
  final DateTime createdAt;

  /// The date the user's progress record was last updated.
  final DateTime updatedAt;

  /// The date and time of the user's last activity.
  final DateTime? lastActivityAt;

  /// Creates a [UserProgressData] instance.
  UserProgressData({
    required this.userId,
    required this.totalPoints,
    required this.currentLevel,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.levelProgressPercent,
    required this.totalPosts,
    required this.totalComments,
    required this.totalMessages,
    required this.totalLikesReceived,
    required this.totalFollowersGained,
    required this.loginStreak,
    required this.longestLoginStreak,
    required this.lastLoginDate,
    required this.milestonesCompleted,
    required this.achievementsEarned,
    required this.timeSpentMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActivityAt,
  });

  /// Creates a [UserProgressData] instance from a JSON map.
  factory UserProgressData.fromJson(Map<String, dynamic> json) {
    return UserProgressData(
      userId: json['user_id'] ?? '',
      totalPoints: json['total_points'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      currentXp: json['current_xp'] as int? ?? 0,
      xpToNextLevel: json['xp_to_next_level'] as int? ?? 1000,
      levelProgressPercent:
          (json['level_progress_percent'] as num?)?.toDouble() ?? 0.0,
      totalPosts: json['total_posts'] as int? ?? 0,
      totalComments: json['total_comments'] as int? ?? 0,
      totalMessages: json['total_messages'] as int? ?? 0,
      totalLikesReceived: json['total_likes_received'] as int? ?? 0,
      totalFollowersGained: json['total_followers_gained'] as int? ?? 0,
      loginStreak: json['login_streak'] as int? ?? 0,
      longestLoginStreak: json['longest_login_streak'] as int? ?? 0,
      lastLoginDate: json['last_login_date'] != null
          ? DateTime.parse(json['last_login_date'] as String)
          : null,
      milestonesCompleted: json['milestones_completed'] as int? ?? 0,
      achievementsEarned: json['achievements_earned'] as int? ?? 0,
      timeSpentMinutes: json['time_spent_minutes'] as int? ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
    );
  }
}

/// Represents a summary of user's overall progress.
class UserProgressModel {
  /// The unique identifier for the user.
  final String userId;

  /// Total points earned by the user.
  final int totalPoints;

  /// The user's current level.
  final int level;

  /// The user's global leaderboard rank.
  final int rank;

  /// Total number of lessons completed.
  final int lessonsCompleted;

  /// Total number of quizzes taken.
  final int quizzesTaken;

  /// The average score across all quizzes.
  final double quizAverageScore;

  /// Total study time in minutes.
  final int totalStudyTimeMinutes;

  /// Total AR projects created.
  final int arProjectsCreated;

  /// Total AR projects completed.
  final int arProjectsCompleted;

  /// Total physics circuits simulated.
  final int circuitsSimulated;

  /// Total components used in build mode.
  final int componentsUsed;

  /// Current login streak in days.
  final int streakDays;

  /// The date and time the user was last active.
  final DateTime lastActive;

  /// Total count of achievements earned.
  final int achievementsCount;

  /// The user's percentile rank for points.
  final double pointsPercentile;

  /// The user's percentile rank for lessons completed.
  final double lessonsPercentile;

  /// The user's percentile rank for projects completed.
  final double projectsPercentile;

  /// Total posts created.
  final int postsCreated;

  /// Total comments made.
  final int commentsMade;

  /// Total likes received.
  final int likesReceived;

  /// Total number of followers.
  final int followersCount;

  /// Total number of followed users.
  final int followingCount;

  /// Creates a [UserProgressModel] instance.
  UserProgressModel({
    required this.userId,
    required this.totalPoints,
    required this.level,
    required this.rank,
    required this.lessonsCompleted,
    required this.quizzesTaken,
    required this.quizAverageScore,
    required this.totalStudyTimeMinutes,
    required this.arProjectsCreated,
    required this.arProjectsCompleted,
    required this.circuitsSimulated,
    required this.componentsUsed,
    required this.streakDays,
    required this.lastActive,
    required this.achievementsCount,
    required this.pointsPercentile,
    required this.lessonsPercentile,
    required this.projectsPercentile,
    required this.postsCreated,
    required this.commentsMade,
    required this.likesReceived,
    required this.followersCount,
    required this.followingCount,
  });

  /// Creates a [UserProgressModel] instance from a JSON map.
  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      userId: json['user_id'] ?? '',
      totalPoints: json['total_points'] ?? 0,
      level: json['level'] ?? 1,
      rank: json['rank'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      quizzesTaken: json['quizzes_taken'] ?? 0,
      quizAverageScore: (json['quiz_average_score'] ?? 0.0).toDouble(),
      totalStudyTimeMinutes: json['total_study_time_minutes'] ?? 0,
      arProjectsCreated: json['ar_projects_created'] ?? 0,
      arProjectsCompleted: json['ar_projects_completed'] ?? 0,
      circuitsSimulated: json['circuits_simulated'] ?? 0,
      componentsUsed: json['components_used'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : DateTime.now(),
      achievementsCount: json['achievements_count'] ?? 0,
      pointsPercentile: (json['points_percentile'] ?? 0.0).toDouble(),
      lessonsPercentile: (json['lessons_percentile'] ?? 0.0).toDouble(),
      projectsPercentile: (json['projects_percentile'] ?? 0.0).toDouble(),
      postsCreated: json['posts_created'] ?? 0,
      commentsMade: json['comments_made'] ?? 0,
      likesReceived: json['likes_received'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }

  /// The progress towards the next level as a decimal between 0.0 and 1.0.
  double get levelProgress => (totalPoints % 1000) / 1000.0;

  /// The number of points needed to reach the next level.
  int get pointsToNextLevel => ((level * 1000) - totalPoints).clamp(0, 1000);
}

/// Represents a weekly learning goal for a user.
class WeeklyGoalModel {
  /// Unique identifier for the goal record.
  final String id;

  /// The ID of the user who owns this goal.
  final String userId;

  /// The type of goal (e.g., 'study_time').
  final String goalType;

  /// The target value for the weekly goal.
  final int targetValue;

  /// The current progress towards the target value.
  final int currentValue;

  /// Whether the weekly goal has been completed.
  final bool isCompleted;

  /// The date and time when the goal was set.
  final DateTime createdAt;

  /// Creates a [WeeklyGoalModel] instance.
  WeeklyGoalModel({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.isCompleted,
    required this.createdAt,
  });

  /// Creates a [WeeklyGoalModel] instance from a JSON map.
  factory WeeklyGoalModel.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      goalType: json['goal_type'] ?? '',
      targetValue: json['target_value'] ?? 0,
      currentValue: json['current_value'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
