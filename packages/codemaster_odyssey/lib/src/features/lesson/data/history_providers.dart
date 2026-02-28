import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/snippet_history.dart';
import 'history_repository.dart';

/// Provider for the [HistoryRepository].
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final client = ref.watch(odysseySupabaseClientProvider);
  return HistoryRepository(client);
});

/// Provider for the latest snippet for a specific lesson.
final latestSnippetProvider = FutureProvider.family<SnippetHistory?, String>((
  ref,
  lessonId,
) {
  final repository = ref.watch(historyRepositoryProvider);
  // We need the current user ID
  final userId = ref.watch(odysseyUserIdProvider);
  if (userId == null) return null;
  return repository.getLatestSnippet(userId, lessonId);
});

/// Provider for the [SupabaseClient].
/// This should be overridden in the main app to provide the real client.
final odysseySupabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw UnimplementedError('odysseySupabaseClientProvider must be overridden');
});

/// Provider for the current user's ID within the Odyssey package.
/// This should be overridden in the main app.
final odysseyUserIdProvider = Provider<String?>((ref) => null);
