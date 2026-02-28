import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../gamification/data/leaderboard_entry_model.dart';

/// Provider for the [LeaderboardRepository] instance.
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(Supabase.instance.client);
});

/// Repository responsible for fetching leaderboard data from Supabase views.
///
/// Provides methods to retrieve top students, mentors, and challenge
/// champions. Returns empty lists if the service is unavailable.
class LeaderboardRepository {
  final SupabaseClient _client;

  /// Creates a [LeaderboardRepository] with a [SupabaseClient].
  LeaderboardRepository(this._client);

  /// Fetches the top users ranked by challenge wins.
  ///
  /// Limits the results to the specified [limit] (default 50).
  Future<List<LeaderboardEntry>> getChallengeChampions({int limit = 50}) async {
    try {
      final response =
          await _client.from('view_challenge_champions').select().limit(limit);

      final data = response as List;
      return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch champions', error: e);
      return [];
    }
  }

  /// Fetches the top users ranked by mentoring points or activity.
  ///
  /// Limits the results to the specified [limit] (default 50).
  Future<List<LeaderboardEntry>> getTopMentors({int limit = 50}) async {
    try {
      final response =
          await _client.from('view_top_mentors').select().limit(limit);

      final data = response as List;
      return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch top mentors', error: e);
      return [];
    }
  }

  /// Fetches the top users ranked by student Karma or performance.
  ///
  /// Limits the results to the specified [limit] (default 50).
  Future<List<LeaderboardEntry>> getTopStudents({int limit = 50}) async {
    try {
      final response =
          await _client.from('view_top_students').select().limit(limit);

      final data = response as List;
      return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch top students', error: e);
      return [];
    }
  }
}
