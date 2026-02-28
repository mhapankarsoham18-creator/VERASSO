import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/security/moderation_service.dart';
import 'package:verasso/core/services/supabase_service.dart';
import '../../gamification/services/gamification_event_bus.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../discovery/domain/weighted_tag_scorer.dart';
import 'post_model.dart';

/// Provides access to the [FeedRepository] via Riverpod.
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final eventBus = ref.watch(gamificationEventBusProvider);
  final moderation = ref.watch(moderationServiceProvider);
  return FeedRepository(
    eventBus: eventBus,
    moderationService: moderation,
  );
});

/// Repository responsible for managing social feed data and interactions.
///
/// This class encapsulates all Supabase access for creating, fetching, and
/// updating posts as well as computing personalized feeds.
class FeedRepository {
  final SupabaseClient _client;
  final GamificationEventBus? _eventBus;
  final ModerationService _moderationService;

  /// Creates a [FeedRepository] with an optional Supabase [client].
  FeedRepository({
    SupabaseClient? client,
    GamificationEventBus? eventBus,
    ModerationService? moderationService,
  })  : _client = client ?? SupabaseService.client,
        _eventBus = eventBus,
        _moderationService = moderationService ?? ModerationService();

  /// Creates a comment on a post (Bridge method for tests).
  Future<void> createComment(String postId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppAuthException('User not logged in');

    try {
      await _client.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
      });

      // Award XP via Event Bus
      _eventBus?.track(GamificationAction.commentWritten, userId);
    } catch (e, stack) {
      AppLogger.error('Create comment error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to create comment', null, e);
    }
  }

  /// Creates a new social post for the given [userId].
  ///
  /// Optionally uploads an [image] to Supabase storage and associates its
  /// public URL with the post. Adds XP through the gamification repository
  /// when creation succeeds.
  Future<void> createPost({
    required String userId,
    String? content,
    List<File> images = const [],
    File? audio,
    List<String> tags = const [],
    List<String>? mediaUrls,
    bool isPersonal = false,
  }) async {
    final List<String> effectiveMediaUrls = List.from(mediaUrls ?? []);
    String? audioUrl;

    // Upload Images
    for (var image in images) {
      try {
        final compressedImage =
            await ImageCompressionService.compressImage(image);
        final fileName =
            'posts/${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg';
        await _client.storage.from('posts').upload(fileName, compressedImage);
        final url = _client.storage.from('posts').getPublicUrl(fileName);
        effectiveMediaUrls.add(url);
      } catch (e, stack) {
        AppLogger.error('Image upload error', error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    // Upload Audio
    if (audio != null) {
      try {
        final fileName = 'audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _client.storage.from('posts').upload(fileName, audio);
        audioUrl = _client.storage.from('posts').getPublicUrl(fileName);
      } catch (e, stack) {
        AppLogger.error('Audio upload error', error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    final post = {
      'user_id': userId,
      'content': content,
      'media_urls': effectiveMediaUrls,
      'audio_url': audioUrl,
      'media_type': images.isNotEmpty || (mediaUrls?.isNotEmpty ?? false)
          ? 'image'
          : (audio != null ? 'audio' : 'text'),
      'tags': tags,
      'is_personal': isPersonal,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _client.from('posts').insert(post);

      // Award XP via Event Bus
      _eventBus?.track(GamificationAction.postCreated, userId);
    } catch (e, stack) {
      AppLogger.error('Create post error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to create post', null, e);
    }
  }

  /// Deletes a post owned by the current user.
  Future<void> deletePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppAuthException('User not logged in');

    try {
      await _client
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Delete post error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to delete post', null, e);
    }
  }

  /// Returns the global feed ordered by recency, optionally re-ranked using
  /// [userInterests] to highlight more relevant content. Supports pagination and muting.
  Future<List<Post>> getFeed({
    List<String> userInterests = const [],
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final myId = _client.auth.currentUser?.id;
      final mutedIds = myId != null
          ? await _moderationService.getMutedUserIds(myId)
          : <String>[];

      var query = _client.from('posts').select('''
            *,
            profiles:user_id(full_name, avatar_url),
            is_liked:post_likes!left(id).eq(user_id, ${myId != null ? "'$myId'" : "'00000000-0000-0000-0000-000000000000'"})
          ''');

      if (mutedIds.isNotEmpty) {
        query = query.not('user_id', 'in', '(${mutedIds.join(',')})');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final posts = (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['is_liked'] = (data['is_liked'] as List?)?.isNotEmpty ?? false;
        return Post.fromJson(data);
      }).toList();

      if (userInterests.isNotEmpty) {
        // Sort by relevance score
        posts.sort((a, b) {
          final scoreA = WeightedTagScorer.score(
            itemTags: a.tags,
            userInterests: userInterests,
            popularityScore: a.likesCount,
            createdAt: a.createdAt,
          );
          final scoreB = WeightedTagScorer.score(
            itemTags: b.tags,
            userInterests: userInterests,
            popularityScore: b.likesCount,
            createdAt: b.createdAt,
          );
          return scoreB.compareTo(scoreA); // Descending
        });
      }

      return posts;
    } catch (e, stack) {
      AppLogger.error('Get feed error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to fetch posts', null, e);
    }
  }

  /// Alias for [getFeed] to support legacy tests.
  @Deprecated('Use getFeed instead')
  Future<List<Post>> getFeedPosts({
    List<String> userInterests = const [],
    int limit = 20,
    int offset = 0,
  }) =>
      getFeed(userInterests: userInterests, limit: limit, offset: offset);

  /// Returns a feed consisting only of posts authored by accounts the user
  /// follows.
  ///
  /// If [userId] is not provided, the currently authenticated user is used.
  /// Throws [AppAuthException] if there is no logged-in user.
  Future<List<Post>> getFollowingFeed({String? userId}) async {
    final myId = userId ?? _client.auth.currentUser?.id;
    if (myId == null) throw const AppAuthException('User not logged in');

    try {
      // 1. Get IDs of people I follow
      final followResponse = await _client
          .from('relationships')
          .select('target_id')
          .eq('user_id', myId)
          .eq('status',
              'friends'); // In this system, 'friends' acts as bidirectional following or simple following

      final followingIds = (followResponse as List)
          .map((e) => e['target_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // 2. Fetch posts from those users
      final postsResponse = await _client
          .from('posts')
          .select('''
            *,
            profiles:user_id(full_name, avatar_url),
            is_liked:post_likes!left(id).eq(user_id, '$myId')
          ''')
          .inFilter('user_id', followingIds)
          .order('created_at', ascending: false);

      return (postsResponse as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['is_liked'] = (data['is_liked'] as List?)?.isNotEmpty ?? false;
        return Post.fromJson(data);
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Get following feed error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to fetch following feed', null, e);
    }
  }

  /// Fetches a single post by its unique [postId].
  Future<Post> getPostById(String postId) async {
    try {
      final myId = _client.auth.currentUser?.id;
      final response = await _client.from('posts').select('''
            *,
            profiles:user_id(full_name, avatar_url),
            is_liked:post_likes!left(id).eq(user_id, ${myId != null ? "'$myId'" : "'00000000-0000-0000-0000-000000000000'"})
          ''').eq('id', postId).single();

      final data = Map<String, dynamic>.from(response);
      data['is_liked'] = (data['is_liked'] as List?)?.isNotEmpty ?? false;
      return Post.fromJson(data);
    } catch (e, stack) {
      AppLogger.error('Get post by ID error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to fetch post', null, e);
    }
  }

  /// Fetches all posts created by the specified [userId], ordered by
  /// `created_at` descending.
  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final myId = _client.auth.currentUser?.id;
      final response = await _client.from('posts').select('''
            *,
            profiles:user_id(full_name, avatar_url),
            is_liked:post_likes!left(id).eq(user_id, ${myId != null ? "'$myId'" : "'00000000-0000-0000-0000-000000000000'"})
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['is_liked'] = (data['is_liked'] as List?)?.isNotEmpty ?? false;
        return Post.fromJson(data);
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Get user posts error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to fetch user posts', null, e);
    }
  }

  /// Toggles the like state for the current user on the post with [postId].
  ///
  /// Uses the `toggle_post_like` Supabase RPC. Throws [AppAuthException] if
  /// there is no authenticated user.
  Future<void> likePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppAuthException('User not logged in');

    try {
      await _client.rpc('toggle_post_like', params: {
        'p_post_id': postId,
        'p_user_id': userId,
      });

      // Award XP for liking (if not on cooldown)
      _eventBus?.track(GamificationAction.likeGiven, userId);
    } catch (e, stack) {
      AppLogger.error('Failed to toggle like', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to toggle like', null, e);
    }
  }

  /// Searches posts whose content or tags match the provided [query].
  ///
  /// Returns posts ordered by recency, including basic profile information
  /// for each post author.
  Future<List<Post>> searchPosts(String query) async {
    try {
      final myId = _client.auth.currentUser?.id;
      final response = await _client
          .from('posts')
          .select('''
            *,
            profiles:user_id(full_name, avatar_url),
            is_liked:post_likes!left(id).eq(user_id, ${myId != null ? "'$myId'" : "'00000000-0000-0000-0000-000000000000'"})
          ''')
          .or('content.ilike.%$query%,tags.cs.{$query}')
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['is_liked'] = (data['is_liked'] as List?)?.isNotEmpty ?? false;
        return Post.fromJson(data);
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Search posts error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Search posts failed', null, e);
    }
  }

  /// Shares a post using the platform's native share sheet.
  Future<void> sharePost(Post post) async {
    final baseUrl = 'https://verasso.app/post';
    final shareContent =
        '${post.content ?? "Check out this post on Verasso!"}\n\n'
        'Read more: $baseUrl/${post.id}';

    // ignore: deprecated_member_use
    await Share.share(shareContent, subject: 'Shared from Verasso');
  }

  /// Removes a like from a post.
  Future<void> unlikePost(String postId) async {
    // Current toggle_post_like RPC handles both like and unlike.
    // This method is a semantic alias for consistency in tests.
    await likePost(postId);
  }

  /// Updates the textual content of an existing post owned by the current
  /// user and marks it as edited.
  ///
  /// Throws [AppAuthException] if there is no authenticated user.
  Future<void> updatePost(
    String postId, [
    String? content,
  ]) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppAuthException('User not logged in');

    try {
      await _client
          .from('posts')
          .update({'content': content, 'is_edited': true})
          .eq('id', postId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Update post error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to update post', null, e);
    }
  }

  /// Watches for new posts in the global feed in real-time.
  Stream<List<Post>> watchFeed() {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .map((data) => data.map((json) => Post.fromJson(json)).toList());
  }
}
