import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/services/pagination_service.dart';
import '../data/feed_repository.dart';
import '../data/post_model.dart';

/// Provider for the global paginated feed.
final feedProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>((ref) {
  final repo = ref.watch(feedRepositoryProvider);
  return FeedNotifier(repo, ref);
});

/// Provider for the current active feed type.
final feedTypeProvider = StateProvider<FeedType>((ref) => FeedType.global);

/// Provider for toggling between standard and video-only feed.
final isVideoFeedProvider = StateProvider<bool>((ref) => false);

/// Provider for real-time feed updates.
final realtimeFeedProvider = StreamProvider<List<Post>>((ref) {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.watchFeed();
});

/// Notifier for the paginated community feed.
class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final FeedRepository _repo;
  final Ref _ref;

  /// Creates a [FeedNotifier] and triggers initial feed load.
  FeedNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadInitialFeed();
  }

  /// Creates a new post for the current user.
  ///
  /// Proxies call to repository and refreshes the feed on success.
  Future<void> createPost({
    required String userId,
    String? content,
    List<String> tags = const [],
    List<File> images = const [],
    File? audio,
    bool isPersonal = false,
  }) async {
    await _repo.createPost(
      userId: userId,
      content: content,
      tags: tags,
      images: images,
      audio: audio,
      isPersonal: isPersonal,
    );
    await loadInitialFeed();
  }

  /// Fetches the initial page of the feed based on the active [FeedType].
  ///
  /// Resets the paginated state and updates the [feedPaginationProvider].
  Future<void> loadInitialFeed() async {
    state = const AsyncValue.loading();
    try {
      final type = _ref.read(feedTypeProvider);
      List<Post> posts;
      if (type == FeedType.following) {
        posts = await _repo.getFollowingFeed();
      } else {
        posts = await _repo.getFeed(limit: 20, offset: 0);
      }
      state = AsyncValue.data(posts);

      // Provider for standard pagination metadata is imported from core/services/pagination_service.dart
      _ref.read(feedPaginationProvider.notifier).updateResults(
            totalItems: posts.length,
            hasMore: posts.length == 20,
          );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Fetches the next page of posts if available.
  ///
  /// Appends results to the current state and updates [feedPaginationProvider].
  Future<void> loadNextPage() async {
    final currentPosts = state.value ?? [];
    final pagination = _ref.read(feedPaginationProvider);
    if (!pagination.hasMore || pagination.isLoading) return;

    try {
      final type = _ref.read(feedTypeProvider);
      List<Post> newPosts;
      if (type == FeedType.following) {
        newPosts = [];
      } else {
        newPosts = await _repo.getFeed(limit: 20, offset: currentPosts.length);
      }

      if (newPosts.isNotEmpty) {
        state = AsyncValue.data([...currentPosts, ...newPosts]);
        _ref.read(feedPaginationProvider.notifier).updateResults(
              totalItems: currentPosts.length + newPosts.length,
              hasMore: newPosts.length == 20,
            );
      } else {
        _ref.read(feedPaginationProvider.notifier).updateResults(
              totalItems: currentPosts.length,
              hasMore: false,
            );
      }
    } catch (e) {
      // Silently fail or log for background loads
    }
  }

  /// Shares a post using the repository's share logic.
  Future<void> sharePost(Post post) async {
    await _repo.sharePost(post);
  }

  /// Toggles the like status of a post.
  ///
  /// Uses the repository to update the database and optimizes the local state
  /// for immediate feedback.
  Future<void> toggleLike(String postId) async {
    final previousState = state;
    final currentPosts = state.value ?? [];
    final postIndex = currentPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentPosts[postIndex];
    final isLiked = post.isLiked;
    final newLikesCount = isLiked ? post.likesCount - 1 : post.likesCount + 1;
    final updatedPost = post.copyWith(
      isLiked: !isLiked,
      likesCount: newLikesCount < 0 ? 0 : newLikesCount,
    );

    // Optimistic Update
    final newPosts = List<Post>.from(currentPosts);
    newPosts[postIndex] = updatedPost;
    state = AsyncValue.data(newPosts);

    try {
      await _repo.likePost(postId);
    } catch (e) {
      AppLogger.error('Toggle like error', error: e);
      // Revert if failed
      state = previousState;
    }
  }

  /// Updates an existing post's content.
  ///
  /// Refreshes the feed after successful update.
  Future<void> updatePost({
    required String postId,
    required String content,
  }) async {
    await _repo.updatePost(postId, content);
    await loadInitialFeed();
  }
}

/// Enum defining the variants of feeds available.
enum FeedType {
  /// The global community feed.
  global,

  /// Feed consisting of posts from users being followed.
  following
}
