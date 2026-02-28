import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/comment_model.dart';
import '../data/comment_repository.dart';

/// Provider for [CommentsNotifier] indexed by [postId].
final commentsProvider = StateNotifierProvider.family<CommentsNotifier,
    AsyncValue<List<Comment>>, String>((ref, postId) {
  final repo = ref.watch(commentRepositoryProvider);
  return CommentsNotifier(repo, postId);
});

/// Notifier for managing the state of comments for a specific post.
class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final CommentRepository _repository;
  final String _postId;
  RealtimeChannel? _subscription;

  /// Creates a [CommentsNotifier] and initializes comment loading and real-time subscription.
  CommentsNotifier(this._repository, this._postId)
      : super(const AsyncValue.loading()) {
    loadComments();
    _subscribe();
  }

  /// Adds a comment to the post and handles error state if the operation fails.
  Future<void> addComment(String content) async {
    try {
      await _repository.addComment(
        postId: _postId,
        content: content,
      );
      // Real-time subscription will handle adding it to the list usually,
      // but we can also optimistically add it or wait for the event.
      // If we use .select().single() it returns the comment.
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  /// Loads comments from the repository.
  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getComments(_postId));
  }

  void _subscribe() {
    _subscription = _repository.subscribeToComments(_postId, (comment) {
      final currentComments = state.value ?? [];
      if (!currentComments.any((c) => c.id == comment.id)) {
        state = AsyncValue.data([...currentComments, comment]);
      }
    });
  }
}
