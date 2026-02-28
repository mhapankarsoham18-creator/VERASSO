import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../../../../core/services/image_compression_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../gamification/services/gamification_event_bus.dart';
import 'profile_model.dart';

/// Stream provider that watches the profile of the currently authenticated user.
final currentUserProfileProvider = StreamProvider<Profile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.id);
});

/// Provider for the [ProfileRepository] which handles data persistence for user profiles.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final eventBus = ref.watch(gamificationEventBusProvider);
  return ProfileRepository(eventBus: eventBus);
});

/// Repository for managing and observing user profile data via Supabase.
class ProfileRepository {
  final SupabaseClient _client;
  final GamificationEventBus? _eventBus;

  /// Creates a [ProfileRepository] with an optional [SupabaseClient].
  ProfileRepository({
    SupabaseClient? client,
    GamificationEventBus? eventBus,
  })  : _client = client ?? SupabaseService.client,
        _eventBus = eventBus;

  /// Alias for [updateProfile] for test compatibility.
  /// Supports both a full [profile] object or individual fields.
  Future<void> createProfile({
    Profile? profile,
    String? userId,
    String? fullName,
    String? email,
    String? username,
  }) async {
    if (profile != null) {
      return updateProfile(profile);
    }

    if (userId == null) {
      throw ArgumentError('userId is required if profile is null');
    }

    final newProfile = Profile(
      id: userId,
      fullName: fullName,
      username: username ?? email?.split('@')[0],
    );
    return updateProfile(newProfile);
  }

  /// Deletes a user profile and associated data.
  Future<void> deleteProfile(String userId) async {
    try {
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e, stack) {
      AppLogger.error('Delete profile error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to delete profile: $e');
    }
  }

  /// Follows a user.
  Future<void> followUser(String followerId, String followedId) async {
    try {
      await _client.from('user_follows').insert({
        'follower_id': followerId,
        'followed_id': followedId,
      });

      // Gamification Hook
      _eventBus?.track(GamificationAction.friendMade, followerId);
      _eventBus?.track(GamificationAction.friendMade, followedId);
    } catch (e, stack) {
      AppLogger.error('Follow user error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Fetches a profile by [userId].
  Future<Profile?> getProfile(String userId) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', userId).single();
      return Profile.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Get profile error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }

  /// Fetches multiple profiles by their IDs.
  /// If [userIds] is null or empty, returns an empty list.
  Future<List<Profile>> getProfiles([List<String>? userIds]) async {
    if (userIds == null || userIds.isEmpty) return [];
    try {
      final response =
          await _client.from('profiles').select().inFilter('id', userIds);
      return (response as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e, stack) {
      AppLogger.error('Get profiles error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Fetches social and engagement statistics for a [userId].
  Future<Map<String, dynamic>> getProfileStats(String userId) async {
    try {
      final response = await _client
          .rpc('get_profile_stats', params: {'target_user_id': userId});
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      AppLogger.error('Get profile stats error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return {'friends_count': 0};
    }
  }

  /// Checks if [followerId] is following [followedId].
  Future<bool> isFollowing(String followerId, String followedId) async {
    try {
      final response = await _client
          .from('user_follows')
          .select()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId)
          .maybeSingle();
      return response != null;
    } catch (e, stack) {
      AppLogger.warning('Is following check failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return false;
    }
  }

  /// Checks if a [username] is currently available.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();
      return response == null;
    } catch (e, stack) {
      AppLogger.error('Check username availability error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return true; // Safest fallback - let signup attempt and catch it then
    }
  }

  /// Alias for [searchUsers] for test compatibility.
  Future<List<Profile>> searchProfiles(String query) => searchUsers(query);

  /// Searches for users whose full name matches the [query].
  Future<List<Profile>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await _client
          .from('profiles')
          .select()
          .textSearch('full_name', query, config: 'english')
          .limit(20);
      return (response as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e, stack) {
      AppLogger.error('Search users error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Unfollows a user.
  Future<void> unfollowUser(String followerId, String followedId) async {
    try {
      await _client
          .from('user_follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId);
    } catch (e, stack) {
      AppLogger.error('Unfollow user error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Uploads and updates the profile avatar for [userId].
  Future<void> updateAvatar(String userId, String path) async {
    try {
      final imageFile = File(path);

      // Compress image before upload
      final compressedImage =
          await ImageCompressionService.compressImage(imageFile);

      final fileName =
          'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('avatars').upload(fileName, compressedImage);
      final url = _client.storage.from('avatars').getPublicUrl(fileName);

      // Update profile with new avatar URL
      await _client
          .from('profiles')
          .update({'avatar_url': url}).eq('id', userId);

      AppLogger.info('Avatar updated successfully for $userId');
    } catch (e, stack) {
      AppLogger.error('Update avatar error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to update avatar: $e');
    }
  }

  /// Updates an existing profile or inserts a new one.
  Future<void> updateProfile(
    Profile? profile, {
    String? userId,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      if (profile != null) {
        await _client.from('profiles').upsert(profile.toJson());
        
        // Gamification check: if profile has bio and avatar, track completion
        if (profile.bio != null && profile.bio!.isNotEmpty && profile.avatarUrl != null) {
          _eventBus?.track(GamificationAction.profileCompleted, profile.id);
        }
        return;
      }

      if (userId == null) {
        throw ArgumentError('userId is required if profile is null');
      }

      await _client.from('profiles').update({
        if (fullName != null) 'full_name': fullName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // We don't have the full profile to check completeness robustly here, but we can do a naive check:
      if (bio != null && bio.isNotEmpty && avatarUrl != null) {
        _eventBus?.track(GamificationAction.profileCompleted, userId);
      }
    } catch (e, stack) {
      AppLogger.error('Update profile error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Alias for [updateAvatar] for test compatibility.
  Future<void> uploadAvatar(String userId, String path) =>
      updateAvatar(userId, path);

  /// Watches a profile for changes in real-time.
  Stream<Profile?> watchProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isEmpty ? null : Profile.fromJson(data.first));
  }
}
