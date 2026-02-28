import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/snippet_history.dart';

/// Repository for managing code snippet history in CodeMaster Odyssey.
/// Interacts with the `codedex_history` table in Supabase.
class HistoryRepository {
  final SupabaseClient _client;

  /// Creates a [HistoryRepository] with the given [SupabaseClient].
  HistoryRepository(this._client);

  /// Fetches the snippet history for a specific user and lesson.
  Future<List<SnippetHistory>> getHistory(
    String userId,
    String lessonId,
  ) async {
    try {
      final response = await _client
          .from('codedex_history')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SnippetHistory.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches the latest snippet for a specific user and lesson.
  Future<SnippetHistory?> getLatestSnippet(
    String userId,
    String lessonId,
  ) async {
    try {
      final response = await _client
          .from('codedex_history')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return SnippetHistory.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Saves a user's code snippet to the history.
  Future<void> saveSnippet(SnippetHistory history) async {
    try {
      await _client.from('codedex_history').insert(history.toJson());
    } catch (e) {
      // In a production app, we'd use a logger here
      rethrow;
    }
  }
}
