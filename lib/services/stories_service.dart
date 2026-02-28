import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';

import '../core/monitoring/app_logger.dart';
import '../core/monitoring/sentry_service.dart';
import '../features/stories/models/highlight_model.dart';

/// Service for managing user stories, highlights, and reactions.
class StoriesService {
  final SupabaseClient _supabase;

  /// Creates a [StoriesService].
  StoriesService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Compress video using video_compress package
  Future<File?> compressVideo(File file, {Function(double)? onProgress}) async {
    try {
      final subscription =
          VideoCompress.compressProgress$.subscribe((progress) {
        if (onProgress != null) onProgress(progress / 100);
      });

      const config = VideoQuality.MediumQuality;
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: config,
        deleteOrigin: false,
        includeAudio: true,
      );
      subscription.unsubscribe();
      return info?.file;
    } catch (e, stack) {
      AppLogger.warning('Video compression failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null; // Return original file if compression fails
    }
  }

  /// Create a new highlight
  Future<HighlightModel> createHighlight({
    required String title,
    required List<String> storyIds,
    File? coverImage,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');
      final userId = currentUser.id;
      String? coverUrl;

      if (coverImage != null) {
        final fileName =
            'highlights/${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
        await _supabase.storage
            .from('user-stories')
            .upload(fileName, coverImage);
        coverUrl =
            _supabase.storage.from('user-stories').getPublicUrl(fileName);
      } else if (storyIds.isNotEmpty) {
        // Use first story's thumbnail/image as cover if none provided
        // This logic mimics Instagram where you pick a story as cover
        // For simplicity, we just won't set coverUrl if not provided,
        // or frontend can pass the url of a story image.
        // But usually Highlights save a separate cover image.
      }

      final response = await _supabase
          .from('user_highlights')
          .insert({
            'user_id': userId,
            'title': title,
            'story_ids': storyIds,
            'cover_url': coverUrl,
          })
          .select()
          .single();

      return HighlightModel.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Failed to create highlight', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to create highlight: $e');
    }
  }

  /// Create a new story
  Future<StoryModel> createStory({
    required File mediaFile,
    required String mediaType,
    String? caption,
    int duration = 5,
    Function(double)? onProgress,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');
      final userId = currentUser.id;
      File fileToUpload = mediaFile;

      // Compress video if needed
      if (mediaType == 'video') {
        final compressedFile =
            await compressVideo(mediaFile, onProgress: onProgress);
        if (compressedFile != null) {
          fileToUpload = compressedFile;
        }
      }

      // Upload media to storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId.${mediaType == 'image' ? 'jpg' : 'mp4'}';
      final filePath = 'stories/$userId/$fileName';

      await _supabase.storage
          .from('user-stories')
          .upload(filePath, fileToUpload);

      // Get public URL
      final mediaUrl =
          _supabase.storage.from('user-stories').getPublicUrl(filePath);

      // Create story record
      final response = await _supabase
          .from('user_stories')
          .insert({
            'user_id': userId,
            'media_url': mediaUrl,
            'media_type': mediaType,
            'caption': caption,
            'duration': duration,
            'expires_at':
                DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          })
          .select()
          .single();

      return StoryModel.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Failed to create story', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to create story: $e');
    }
  }

  /// Delete a highlight
  Future<void> deleteHighlight(String highlightId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      final userId = currentUser.id;
      await _supabase
          .from('user_highlights')
          .delete()
          .eq('id', highlightId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Failed to delete highlight', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to delete highlight: $e');
    }
  }

  /// Delete your own story
  Future<void> deleteStory(String storyId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      final userId = currentUser.id;

      // Get story to find media URL
      final story = await _supabase
          .from('user_stories')
          .select('media_url')
          .eq('id', storyId)
          .eq('user_id', userId)
          .single();

      // Delete from storage
      final mediaPath = Uri.parse(story['media_url']).path;
      // Handle potential path issues if full URL
      final storagePath = mediaPath.split('/user-stories/').last;

      await _supabase.storage.from('user-stories').remove([storagePath]);

      // Delete record
      await _supabase
          .from('user_stories')
          .delete()
          .eq('id', storyId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Failed to delete story', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to delete story: $e');
    }
  }

  /// Get active stories from people you follow
  Future<List<StoryModel>> getActiveStories() async {
    try {
      final response = await _supabase
          .from('active_stories')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stories: $e');
    }
  }

  /// Get all past stories for highlight creation
  Future<List<StoryModel>> getArchivedStories() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];
      final userId = currentUser.id;
      final response = await _supabase
          .from('user_stories')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50); // Limit to last 50 for now

      return (response as List)
          .map((json) => StoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get archived stories: $e');
    }
  }

  /// Get current user's stories.
  Future<List<StoryModel>> getMyStories() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];
      final userId = currentUser.id;
      return await getUserStories(userId);
    } catch (e) {
      throw Exception('Failed to get my stories: $e');
    }
  }

  /// Get multiple stories by their IDs (for highlights)
  Future<List<StoryModel>> getStoriesByIds(List<String> storyIds) async {
    if (storyIds.isEmpty) return [];
    try {
      final response = await _supabase
          .from('user_stories')
          .select()
          .inFilter('id', storyIds);

      return (response as List)
          .map((json) => StoryModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      AppLogger.warning('Failed to get stories by IDs', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Get reactions for a story
  Future<List<StoryReactionModel>> getStoryReactions(String storyId) async {
    try {
      final response = await _supabase
          .from('story_reactions')
          .select()
          .eq('story_id', storyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StoryReactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reactions: $e');
    }
  }

  /// Get who viewed a story
  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    try {
      final response = await _supabase
          .from('story_views')
          .select(
              'viewer_id, viewed_at, auth.users!viewer_id(username, avatar_url)')
          .eq('story_id', storyId)
          .order('viewed_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get viewers: $e');
    }
  }

  /// Get user highlights
  Future<List<HighlightModel>> getUserHighlights(String userId) async {
    try {
      final response = await _supabase
          .from('user_highlights')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HighlightModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      // If table doesn't exist yet, return empty list instead of crashing app flow
      AppLogger.warning('Failed to get user highlights', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  // --- Highlights ---

  /// Get stories for a specific user
  Future<List<StoryModel>> getUserStories(String userId) async {
    try {
      final response = await _supabase
          .from('user_stories')
          .select()
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user stories: $e');
    }
  }

  /// React to a story
  Future<void> reactToStory({
    required String storyId,
    required String reactionType,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      final userId = currentUser.id;

      await _supabase.from('story_reactions').upsert({
        'story_id': storyId,
        'user_id': userId,
        'reaction_type': reactionType,
      });

      // Notify owner
      final story = await _supabase
          .from('user_stories')
          .select('user_id')
          .eq('id', storyId)
          .single();
      final ownerId = story['user_id'] as String;

      if (ownerId != userId) {
        await _supabase.from('notifications').insert({
          'user_id': ownerId,
          'title': 'New Reaction',
          'message': 'Someone reacted $reactionType to your story!',
          'type': 'reaction',
          'data': {
            'story_id': storyId,
            'reaction_type': reactionType,
            'reactor_id': userId
          },
        });
      }
    } catch (e) {
      throw Exception('Failed to react: $e');
    }
  }

  /// Mark story as viewed
  Future<void> viewStory(String storyId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      final userId = currentUser.id;

      // Call the increment function
      await _supabase.rpc('increment_story_views', params: {
        'p_story_id': storyId,
        'p_viewer_id': userId,
      });

      // Notify story owner (if not self)
      // First get story owner
      final story = await _supabase
          .from('user_stories')
          .select('user_id')
          .eq('id', storyId)
          .single();
      final ownerId = story['user_id'] as String;

      if (ownerId != userId) {
        // Check if we should notify (e.g. throttling or first view)
        // For MVP, simplistic notification
        await _supabase.from('notifications').insert({
          'user_id': ownerId,
          'title': 'New Story View',
          'message': 'Someone viewed your story!',
          'type': 'view',
          'data': {'story_id': storyId, 'viewer_id': userId},
          // 'is_read': false // default
        });
      }
    } catch (e, stack) {
      // Ignore if already viewed (unique constraint)
      if (!e.toString().contains('duplicate')) {
        AppLogger.debug('Failed to view story', error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }
  }
}

/// Represents a user's story post.
class StoryModel {
  /// Unique identifier for the story.
  final String id;

  /// The ID of the user who posted the story.
  final String userId;

  /// The URL to the media content (image or video).
  final String mediaUrl;

  /// The type of media (e.g., 'image' or 'video').
  final String mediaType;

  /// An optional caption for the story.
  final String? caption;

  /// The display duration of the story in seconds.
  final int duration;

  /// The total number of views the story has received.
  final int viewsCount;

  /// The date and time when the story was created.
  final DateTime createdAt;

  /// The date and time when the story expires.
  final DateTime expiresAt;

  // User info (from join)
  /// The username of the story author.
  final String? username;

  /// The URL to the author's avatar.
  final String? avatarUrl;

  /// The full name of the author.
  final String? fullName;

  /// Creates a [StoryModel] instance.
  StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.duration,
    required this.viewsCount,
    required this.createdAt,
    required this.expiresAt,
    this.username,
    this.avatarUrl,
    this.fullName,
  });

  /// Creates a [StoryModel] from a JSON map.
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      userId: json['user_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      caption: json['caption'],
      duration: json['duration'] ?? 5,
      viewsCount: json['views_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      username: json['username'],
      avatarUrl: json['avatar_url'],
      fullName: json['full_name'],
    );
  }
}

/// Represents a reaction (e.g., like, heart) to a story.
class StoryReactionModel {
  /// Unique identifier for the reaction.
  final String id;

  /// The ID of the story being reacted to.
  final String storyId;

  /// The ID of the user who reacted.
  final String userId;

  /// The type of reaction (e.g., 'heart', 'fire').
  final String reactionType;

  /// The date and time when the reaction was created.
  final DateTime createdAt;

  /// Creates a [StoryReactionModel] instance.
  StoryReactionModel({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.reactionType,
    required this.createdAt,
  });

  /// Creates a [StoryReactionModel] from a JSON map.
  factory StoryReactionModel.fromJson(Map<String, dynamic> json) {
    return StoryReactionModel(
      id: json['id'],
      storyId: json['story_id'],
      userId: json['user_id'],
      reactionType: json['reaction_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
