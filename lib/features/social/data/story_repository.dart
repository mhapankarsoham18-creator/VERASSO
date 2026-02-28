import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/services/supabase_service.dart';
import '../../gamification/services/gamification_event_bus.dart';
import 'story_model.dart';

/// Repository for handling user stories (short-lived media posts).
class StoryRepository {
  final SupabaseClient _client;
  final GamificationEventBus? _eventBus;

  /// Creates a [StoryRepository] with an optional [SupabaseClient].
  StoryRepository({
    SupabaseClient? supabase,
    GamificationEventBus? eventBus,
  })  : _client = supabase ?? SupabaseService.client,
        _eventBus = eventBus;

  /// Archives expired stories.
  Future<void> archiveExpiredStories() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('stories')
          .update({'is_archived': true})
          .lt('expires_at', now)
          .eq('is_archived', false);
    } catch (e) {
      AppLogger.error('Archive stories error', error: e);
    }
  }

  /// Creates a new story.
  /// Handles both [File] uploads and raw [content] (e.g. for tests).
  Future<void> createStory({
    required String userId,
    File? file,
    String? content,
    String mediaType = 'image',
  }) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    try {
      String mediaUrl = content ?? '';

      if (file != null) {
        final fileName =
            'stories/${DateTime.now().millisecondsSinceEpoch}.${mediaType.contains('video') ? 'mp4' : 'jpg'}';
        await _client.storage.from('posts').upload(fileName, file);
        mediaUrl = _client.storage.from('posts').getPublicUrl(fileName);
      }

      await _client.from('stories').insert({
        'user_id': userId,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'content': content,
        'expires_at':
            DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      });

      // Hook for adding XP for story posted
      _eventBus?.track(GamificationAction.storyPosted, myId);
    } catch (e) {
      AppLogger.error('Create story error', error: e);
      throw Exception('Failed to upload story');
    }
  }

  /// Deletes a story.
  Future<void> deleteStory(String storyId) async {
    try {
      await _client.from('stories').delete().eq('id', storyId);
    } catch (e) {
      AppLogger.error('Delete story error', error: e);
    }
  }

  /// Fetches all currently active (non-expired) stories.
  Future<List<Story>> getActiveStories() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _client
          .from('stories')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .gt('expires_at', now)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Fetch active stories error', error: e);
      return [];
    }
  }

  /// Alias for [getActiveStories].
  Future<List<Story>> getStories() => getActiveStories();

  /// Fetches stories for a specific user.
  Future<List<Story>> getStoriesForUser(String userId) async {
    try {
      final response = await _client
          .from('stories')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('user_id', userId);
      return (response as List).map((e) => Story.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Fetch user stories error', error: e);
      return [];
    }
  }

  /// Fetches reactions for a story.
  Future<List<Map<String, dynamic>>> getStoryReactions(String storyId) async {
    try {
      return await _client
          .from('story_reactions')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('story_id', storyId);
    } catch (e) {
      return [];
    }
  }

  /// Fetches views for a story.
  Future<List<Map<String, dynamic>>> getStoryViews(String storyId) async {
    try {
      return await _client
          .from('story_views')
          .select('*, profiles:viewer_id(full_name, avatar_url)')
          .eq('story_id', storyId);
    } catch (e) {
      return [];
    }
  }

  /// Marks a story as viewed by a user.
  Future<void> markStoryAsViewed(String storyId, [String? viewerId]) async {
    final userId = viewerId ?? _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('story_views').upsert({
        'story_id': storyId,
        'viewer_id': userId,
        'viewed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Mark story viewed error', error: e);
    }
  }

  /// Records a reaction to a story.
  Future<void> reactToStory({
    required String storyId,
    String? userId,
    String? reaction,
    String? emoji,
  }) async {
    final effectiveUserId = userId ?? _client.auth.currentUser?.id;
    if (effectiveUserId == null) return;

    final effectiveReaction = reaction ?? emoji ?? 'thumbs_up';
    try {
      await _client.from('story_reactions').upsert({
        'story_id': storyId,
        'user_id': effectiveUserId,
        'reaction': effectiveReaction,
      });
    } catch (e) {
      AppLogger.error('React to story error', error: e);
    }
  }

  /// Alias for [markStoryAsViewed].
  Future<void> viewStory(String storyId, [String? viewerId]) =>
      markStoryAsViewed(storyId, viewerId);
}
