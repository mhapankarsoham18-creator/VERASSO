import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/badge_model.dart';

/// Provider for the [GamificationRepository] instance.
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

/// Repository for managing user gamification data, including XP, levels, streaks, and badges.
class GamificationRepository {
  final SupabaseClient _client;

  /// Creates a [GamificationRepository] with an optional [SupabaseClient].
  GamificationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Retrieves the leaderboard data sorted by total XP.
  Future<List<UserStats>> getLeaderboard() async {
    try {
      final response = await _client
          .from('user_stats')
          .select('*, profiles:user_id(username, full_name, avatar_url)')
          .order('total_xp', ascending: false)
          .limit(50);

      return (response as List).map((e) {
        final profile = e['profiles'] as Map<String, dynamic>?;
        return UserStats(
          userId: e['user_id'],
          username: profile?['username'],
          fullName: profile?['full_name'],
          avatarUrl: profile?['avatar_url'],
          totalXP: e['total_xp'],
          level: e['level'],
          unlockedBadges: [], // Leaderboard usually doesn't need all badges
          currentStreak: e['current_streak'],
          longestStreak: e['longest_streak'],
          subjectProgress: {},
          lastActive: DateTime.parse(e['last_active']),
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Get leaderboard error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Retrieves the current user's statistics, creating them if they don't exist.
  Future<UserStats?> getUserStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_stats')
          .select('*, profiles:user_id(username, full_name, avatar_url)')
          .eq('user_id', userId)
          .single();

      // We also need unlocked badges
      final badgesResponse = await _client
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', userId);

      final unlockedBadges =
          (badgesResponse as List).map((e) => e['badge_id'] as String).toList();

      final profile = response['profiles'] as Map<String, dynamic>?;

      return UserStats(
        userId: response['user_id'],
        username: profile?['username'],
        fullName: profile?['full_name'],
        avatarUrl: profile?['avatar_url'],
        totalXP: response['total_xp'],
        level: response['level'],
        unlockedBadges: unlockedBadges,
        currentStreak: response['current_streak'],
        longestStreak: response['longest_streak'],
        subjectProgress:
            Map<String, int>.from(response['subject_progress'] ?? {}),
        lastActive: DateTime.parse(response['last_active']),
      );
    } catch (e) {
      // If not found, create new stats
      return _initUserStats(userId);
    }
  }

  /// Records daily activity and calculates/updates streaks
  Future<void> recordActivity() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final stats = await getUserStats();
      if (stats == null) return;

      final now = DateTime.now();
      final lastActive = stats.lastActive;

      // Calculate difference in days
      final difference = DateTime(now.year, now.month, now.day)
          .difference(
              DateTime(lastActive.year, lastActive.month, lastActive.day))
          .inDays;

      int newStreak = stats.currentStreak;
      int longestStreak = stats.longestStreak;

      if (difference == 1) {
        // Active on consecutive day
        newStreak++;
      } else if (difference > 1) {
        // Streak broken
        newStreak = 1;
      } else if (difference == 0 && newStreak == 0) {
        // First activity ever
        newStreak = 1;
      }

      if (newStreak > longestStreak) {
        longestStreak = newStreak;
      }

      await _client.from('user_stats').update({
        'current_streak': newStreak,
        'longest_streak': longestStreak,
        'last_active': now.toIso8601String(),
      }).eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Record activity error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Unlocks a badge for the current user atomically.
  Future<void> unlockBadge(String badgeId, {int xpReward = 0}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.rpc('claim_badge', params: {
        'p_user_id': userId,
        'p_badge_id': badgeId,
        'p_xp_reward': xpReward,
      });
    } catch (e, stack) {
      AppLogger.error('Unlock badge error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Increases the current user's XP. Leveling is handled by DB triggers.
  Future<void> updateXP(int additionalXP) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Record activity (calculates streaks)
    await recordActivity();

    final stats = await getUserStats();
    if (stats == null) return;

    final newXP = stats.totalXP + additionalXP;

    try {
      await _client.from('user_stats').update({
        'total_xp': newXP,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Update XP error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Streams the leaderboard data in real-time.
  Stream<List<UserStats>> watchLeaderboard() {
    return _client
        .from('user_stats')
        .stream(primaryKey: ['user_id'])
        .order('total_xp', ascending: false)
        .limit(50)
        .asyncMap((data) async {
          // Since stream().map doesn't support joins easily, we'll manually fetch profiles for these IDs
          // or just accept that the stream might be slightly stale in names until refetch.
          // BUT: Postgrest doesn't support joins in real-time streams as easily.
          // Alternatives: Use a view (which the repo already hints at in leaderboard_repository.dart).

          // For now, let's fetch the profiles for the users in the current stream batch.
          final userIds = data.map((e) => e['user_id'] as String).toList();
          final profilesResponse = await _client
              .from('profiles')
              .select('id, username, full_name, avatar_url')
              .inFilter('id', userIds);

          final profileMap = {
            for (var p in profilesResponse as List) p['id']: p
          };

          return data.map((e) {
            final profile = profileMap[e['user_id']];
            return UserStats(
              userId: e['user_id'],
              username: profile?['username'],
              fullName: profile?['full_name'],
              avatarUrl: profile?['avatar_url'],
              totalXP: e['total_xp'],
              level: e['level'],
              unlockedBadges: [],
              currentStreak: e['current_streak'],
              longestStreak: e['longest_streak'],
              subjectProgress: {},
              lastActive: DateTime.parse(e['last_active']),
            );
          }).toList();
        });
  }

  Future<UserStats> _initUserStats(String userId) async {
    final stats = {
      'user_id': userId,
      'total_xp': 0,
      'level': 1,
      'current_streak': 0,
      'longest_streak': 0,
      'subject_progress': {},
      'last_active': DateTime.now().toIso8601String(),
    };
    try {
      await _client.from('user_stats').upsert(stats);
    } catch (e, stack) {
      AppLogger.error('Init user stats error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
    return UserStats(
      userId: userId,
      totalXP: 0,
      level: 1,
      unlockedBadges: [],
      currentStreak: 0,
      longestStreak: 0,
      subjectProgress: {},
      lastActive: DateTime.now(),
    );
  }
}
