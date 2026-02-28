import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'collection_model.dart';
import 'post_model.dart';

// Riverpod provider for SavedPostRepository
/// Provider for the [SavedPostRepository].
final savedPostRepositoryProvider = Provider<SavedPostRepository>((ref) {
  return SavedPostRepository();
});

/// Repository for managing saved posts, collections, and collaborative curated lists.
class SavedPostRepository {
  final SupabaseClient _client;

  /// Creates a [SavedPostRepository] instance.
  SavedPostRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Creates a new curated [Collection] for the current user.
  Future<void> createCollection(String name,
      {String? description, bool isPrivate = true}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('collections').insert({
      'owner_id': userId,
      'name': name,
      'description': description,
      'is_private': isPrivate,
    });
  }

  /// Retrieves all posts belonging to a specific collection.
  Future<List<Post>> getCollectionPosts(String collectionId) async {
    try {
      final response = await _client
          .from('collection_posts')
          .select('*, posts(*, profiles:user_id(full_name, avatar_url))')
          .eq('collection_id', collectionId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Post.fromJson(e['posts'])).toList();
    } catch (e) {
      return [];
    }
  }

  // Collections & Collaborations
  /// Fetches collections where the user is either the owner or a collaborator.
  Future<List<Collection>> getCollections() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('collections')
          .select()
          .or('owner_id.eq.$userId, collaborator_ids.cs.{$userId}')
          .order('created_at', ascending: false);

      return (response as List).map((e) => Collection.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns a list of all posts bookmarked by the current user.
  Future<List<Post>> getSavedPosts() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('saved_posts')
          .select('*, posts(*, profiles:user_id(full_name, avatar_url))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Post.fromJson(e['posts'])).toList();
    } catch (e) {
      return [];
    }
  }

  /// Checks if a specific post is bookmarked by the user.
  Future<bool> isSaved(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('saved_posts')
        .select()
        .match({'user_id': userId, 'post_id': postId}).maybeSingle();

    return response != null;
  }

  /// Bookmarks a post for the current user.
  Future<void> savePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('saved_posts').upsert({
      'user_id': userId,
      'post_id': postId,
    });
  }

  /// Adds a post to a curated collection.
  Future<void> saveToCollection(String collectionId, String postId) async {
    // This assumes a junction table 'collection_posts' or updating the array in 'collections'
    // Let's assume a junction table for better scalability
    await _client.from('collection_posts').upsert({
      'collection_id': collectionId,
      'post_id': postId,
    });
  }

  /// Removes a bookmark for a specific post.
  Future<void> unsavePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('saved_posts').delete().match({
      'user_id': userId,
      'post_id': postId,
    });
  }

  /// Updates collection details with optimistic locking to prevent conflicts.
  Future<void> updateCollection(Collection collection) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // GAIN: Optimistic Locking for conflict detection
    final response = await _client
        .from('collections')
        .update(
            collection.copyWith(revisionId: collection.revisionId + 1).toJson())
        .match({
      'id': collection.id,
      'revision_id': collection.revisionId,
    }).select();

    if ((response as List).isEmpty) {
      throw Exception(
          'Conflict detected: Collection has been modified by someone else.');
    }
  }

  /// Streams real-time updates for collections owned by the current user.
  Stream<List<Collection>> watchCollections() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    // Use Supabase Realtime to watch for changes in the collections table
    return _client
        .from('collections')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .map((data) => data.map((e) => Collection.fromJson(e)).toList());

    // Note: To truly handle "shared" collections where owner_id != userId,
    // we would need a more complex filter or a separate stream for collaborators.
  }
}
