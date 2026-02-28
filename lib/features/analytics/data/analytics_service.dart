import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/supabase_service.dart';
import '../models/analytics_models.dart';

/// Provider for the [AnalyticsService].
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Provider for the [UserStats] of the currently authenticated user.
final currentUserStatsProvider = FutureProvider<UserStats?>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return null;
  return service.getUserStats(userId);
});

/// Service responsible for tracking and retrieving analytical data.
class AnalyticsService {
  final SupabaseClient _client;

  /// Creates an [AnalyticsService] with an optional Supabase client.
  AnalyticsService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Get content performance stats
  Future<ContentStats?> getContentStats(String contentId) async {
    try {
      final response = await _client
          .from('content_stats')
          .select()
          .eq('content_id', contentId)
          .maybeSingle();

      return response != null ? ContentStats.fromJson(response) : null;
    } catch (e) {
      AppLogger.info('Get content stats error: $e');
      return null;
    }
  }

  /// Get top performing content for a user
  Future<List<ContentStats>> getTopContent(String userId,
      {int limit = 10}) async {
    try {
      // This would need a join with posts table to filter by user
      // For now, simplified version
      final response = await _client
          .from('content_stats')
          .select()
          .order('engagement_rate', ascending: false)
          .limit(limit);

      return (response as List).map((e) => ContentStats.fromJson(e)).toList();
    } catch (e) {
      AppLogger.info('Get top content error: $e');
      return [];
    }
  }

  /// Get user engagement data for the last N days
  Future<List<EngagementData>> getUserEngagement(String userId,
      {int days = 7}) async {
    try {
      final response = await _client.rpc(
        'get_user_engagement',
        params: {'target_user_id': userId, 'days': days},
      );

      return (response as List).map((e) => EngagementData.fromJson(e)).toList();
    } catch (e) {
      AppLogger.info('Get user engagement error: $e');
      return [];
    }
  }

  /// Get user statistics
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final response = await _client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create initial stats
        await _client
            .rpc('update_user_stats', params: {'target_user_id': userId});
        return getUserStats(userId); // Retry
      }

      return UserStats.fromJson(response);
    } catch (e) {
      AppLogger.info('Get user stats error: $e');
      throw DatabaseException('Failed to get user stats', null, e);
    }
  }

  /// Refresh user stats (call after significant actions)
  Future<void> refreshUserStats(String userId) async {
    try {
      await _client
          .rpc('update_user_stats', params: {'target_user_id': userId});
    } catch (e) {
      AppLogger.info('Refresh user stats error: $e');
    }
  }

  /// Track an analytics event
  Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? properties]) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('analytics_events').insert({
        'user_id': userId,
        'event_name': eventName,
        'properties': properties ?? {},
      });
    } catch (e) {
      AppLogger.info('Track event error: $e');
      // Don't throw - analytics failures shouldn't break app
    }
  }

  /// Update content stats (called when content is viewed/liked/etc)
  Future<void> updateContentStats({
    required String contentId,
    required String contentType,
    int? viewsDelta,
    int? likesDelta,
    int? commentsDelta,
    int? sharesDelta,
  }) async {
    try {
      final existing = await _client
          .from('content_stats')
          .select()
          .eq('content_id', contentId)
          .maybeSingle();

      if (existing == null) {
        // Create new
        await _client.from('content_stats').insert({
          'content_id': contentId,
          'content_type': contentType,
          'views_count': viewsDelta ?? 0,
          'likes_count': likesDelta ?? 0,
          'comments_count': commentsDelta ?? 0,
          'shares_count': sharesDelta ?? 0,
        });
      } else {
        // Update existing
        await _client.from('content_stats').update({
          'views_count': (existing['views_count'] ?? 0) + (viewsDelta ?? 0),
          'likes_count': (existing['likes_count'] ?? 0) + (likesDelta ?? 0),
          'comments_count':
              (existing['comments_count'] ?? 0) + (commentsDelta ?? 0),
          'shares_count': (existing['shares_count'] ?? 0) + (sharesDelta ?? 0),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('content_id', contentId);
      }
    } catch (e) {
      AppLogger.info('Update content stats error: $e');
    }
  }
}
