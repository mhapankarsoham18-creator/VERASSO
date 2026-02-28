import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/supabase_service.dart';

import 'profile_model.dart';

/// Provider for [FollowRepository].
final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

/// Repository for managing user follow relationships.
class FollowRepository {
  /// The Supabase client used for follow operations.
  final SupabaseClient _client;

  /// Creates a [FollowRepository] instance.
  FollowRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Follows a user by creating a follow relationship.
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _client.from('follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
      });
    } catch (e, stack) {
      AppLogger.error('Follow user error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Fetches the list of followers for a user.
  Future<List<Profile>> getFollowers(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('follower_id, profiles!inner(*)')
          .eq('following_id', userId);

      return (response as List).map((e) {
        final profileJson = e['profiles'] as Map<String, dynamic>;
        return Profile.fromJson(profileJson);
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Get followers error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Fetches the list of users followed by a user.
  Future<List<Profile>> getFollowing(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('following_id, profiles!inner(*)')
          .eq('follower_id', userId);

      return (response as List).map((e) {
        final profileJson = e['profiles'] as Map<String, dynamic>;
        return Profile.fromJson(profileJson);
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Get following error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Unfollows a user by removing the follow relationship.
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    } catch (e, stack) {
      AppLogger.error('Unfollow user error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to unfollow user: $e');
    }
  }
}
