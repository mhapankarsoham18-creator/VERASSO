import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../gamification/services/gamification_event_bus.dart';
import 'comment_model.dart';

/// Provider for the [CommentRepository] instance.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final eventBus = ref.read(gamificationEventBusProvider);
  return CommentRepository(gamificationEventBus: eventBus);
});

/// Repository for managing comments on social posts.
class CommentRepository {
  final SupabaseClient _client;
  final GamificationEventBus? _gamificationEventBus;

  /// Creates a [CommentRepository] instance.
  CommentRepository({
    SupabaseClient? client,
    GamificationEventBus? gamificationEventBus,
  })  : _client = client ?? SupabaseService.client,
        _gamificationEventBus = gamificationEventBus;

  /// Adds a new comment to a post.
  Future<Comment> addComment({
    required String postId,
    required String content,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _client.auth.currentUser?.id;
    if (effectiveUserId == null) {
      throw const AppAuthException('User not logged in');
    }

    try {
      final response = await _client
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': effectiveUserId,
            'content': content,
          })
          .select('*, profiles:user_id(full_name, avatar_url)')
          .single();

      // Hook into Gamification Event Bus v2
      _gamificationEventBus?.track(
          GamificationAction.commentWritten, effectiveUserId);

      return Comment.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to add comment', error: e);
      throw DatabaseException('Failed to add comment', null, e);
    }
  }

  /// Alias for [addComment] for test compatibility.
  Future<Comment> createComment({
    required String postId,
    required String content,
    String? userId,
  }) =>
      addComment(postId: postId, content: content, userId: userId);

  /// Deletes a comment.
  Future<void> deleteComment(String commentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppAuthException('User not logged in');

    try {
      await _client
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);
    } catch (e) {
      AppLogger.error('Failed to delete comment', error: e);
      throw DatabaseException('Failed to delete comment', null, e);
    }
  }

  /// Fetches comments for a specific [postId].
  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _client
          .from('comments')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List).map((e) => Comment.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch comments', error: e);
      throw DatabaseException('Failed to fetch comments', null, e);
    }
  }

  /// Alias for [getComments] for test compatibility.
  Future<List<Comment>> getPostComments(String postId) => getComments(postId);

  /// Subscribes to real-time comment updates for a [postId].
  RealtimeChannel subscribeToComments(
      String postId, void Function(Comment) onNewComment) {
    return _client
        .channel('public:comments:post_id=eq.$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (payload) async {
            // Need to fetch profile data since real-time payload only has the row
            final newId = payload.newRecord['id'];
            final commentWithProfile = await _client
                .from('comments')
                .select('*, profiles:user_id(full_name, avatar_url)')
                .eq('id', newId)
                .single();
            onNewComment(Comment.fromJson(commentWithProfile));
          },
        )
        .subscribe();
  }
}
