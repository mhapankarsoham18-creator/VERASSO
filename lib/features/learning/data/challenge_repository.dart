import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'challenge_model.dart';

/// Provider for the [ChallengeRepository].
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(Supabase.instance.client);
});

/// Repository for managing community challenges and submissions.
class ChallengeRepository {
  final SupabaseClient _client;

  /// Creates a [ChallengeRepository] instance.
  ChallengeRepository(this._client);

  // 1. Create a Challenge
  /// Creates a new community challenge.
  Future<void> createChallenge({
    required String creatorId,
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required int karmaReward,
  }) async {
    await _client.from('challenges').insert({
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'karma_reward': karmaReward,
      'expires_at': DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(), // Default 1 week
    });
  }

  // 2. Fetch Active Challenges (Battle Arena)
  /// Retrieves all active community challenges.
  Future<List<CommunityChallenge>> getActiveChallenges() async {
    final response = await _client
        .from('challenges')
        .select('*, profiles:creator_id(full_name, avatar_url)')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CommunityChallenge.fromJson(json))
        .toList();
  }

  // 3. Fetch My Created Challenges
  /// Retrieves challenges created by a specific user.
  Future<List<CommunityChallenge>> getMyChallenges(String userId) async {
    final response = await _client
        .from('challenges')
        .select('*, profiles:creator_id(full_name, avatar_url)')
        .eq('creator_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CommunityChallenge.fromJson(json))
        .toList();
  }

  // 4. Submit an Entry
  /// Retrieves all submissions for a specific challenge.
  Future<List<ChallengeSubmission>> getSubmissionsForChallenge(
      String challengeId) async {
    final response = await _client
        .from('challenge_submissions')
        .select('*, profiles:user_id(full_name, avatar_url)')
        .eq('challenge_id', challengeId)
        .order('submitted_at', ascending: false);

    return (response as List)
        .map((json) => ChallengeSubmission.fromJson(json))
        .toList();
  }

  // 5. Fetch Submissions for a Challenge (For Review)
  /// Reviews a challenge submission (Approve/Reject).
  Future<void> reviewSubmission(String submissionId, String status,
      {String? feedback}) async {
    await _client.from('challenge_submissions').update({
      'status': status,
      'feedback': feedback,
    }).eq('id', submissionId);

    // Future: Trigger Karma transaction if Approved
  }

  // 6. Review Submission (Approve/Reject)
  /// Submits an entry for a community challenge.
  Future<void> submitEntry({
    required String challengeId,
    required String userId,
    required String contentUrl,
  }) async {
    await _client.from('challenge_submissions').insert({
      'challenge_id': challengeId,
      'user_id': userId,
      'content_url': contentUrl,
    });
  }
}
