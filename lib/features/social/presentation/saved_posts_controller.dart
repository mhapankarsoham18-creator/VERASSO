import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/collection_model.dart';
import '../data/post_model.dart';
import '../data/saved_post_repository.dart';

/// Stream of post collections owned by or shared with the current user.
final collectionsProvider = StreamProvider<List<Collection>>((ref) {
  final repo = ref.watch(savedPostRepositoryProvider);
  return repo.watchCollections();
});

/// Provider family to check if a specific post is bookmarked.
final isPostSavedProvider =
    FutureProvider.family<bool, String>((ref, postId) async {
  final repo = ref.watch(savedPostRepositoryProvider);
  // We want to re-run this when savedPostsProvider changes
  ref.watch(savedPostsProvider);
  return repo.isSaved(postId);
});

/// Provider for the [SavedPostsController].
final savedPostsControllerProvider =
    StateNotifierProvider<SavedPostsController, AsyncValue<void>>((ref) {
  return SavedPostsController(ref.watch(savedPostRepositoryProvider), ref);
});

/// Provider for the list of bookmarked posts.
final savedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.watch(savedPostRepositoryProvider);
  return repo.getSavedPosts();
});

/// Controller for managing bookmarked posts and curated collections.
class SavedPostsController extends StateNotifier<AsyncValue<void>> {
  final SavedPostRepository _repo;
  final Ref _ref;

  /// Creates a [SavedPostsController] instance.
  SavedPostsController(this._repo, this._ref) : super(const AsyncData(null));

  /// Creates a new curated collection.
  Future<void> createCollection(String name,
      {String? description, bool isPrivate = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.createCollection(name,
          description: description, isPrivate: isPrivate);
      _ref.invalidate(collectionsProvider);
    });
  }

  /// Adds a post to a specific collection.
  Future<void> saveToCollection(String collectionId, String postId) async {
    state = await AsyncValue.guard(() async {
      await _repo.saveToCollection(collectionId, postId);
      // Invalidate specific collection posts if we had a provider for it
    });
  }

  /// Toggles the bookmark status of a post.
  Future<void> toggleSave(String postId) async {
    final isCurrentlySaved = await _repo.isSaved(postId);

    state = await AsyncValue.guard(() async {
      if (isCurrentlySaved) {
        await _repo.unsavePost(postId);
      } else {
        await _repo.savePost(postId);
      }
      _ref.invalidate(savedPostsProvider);
    });
  }
}
