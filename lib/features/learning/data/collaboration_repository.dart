import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/services/supabase_service.dart';
import 'package:verasso/features/learning/data/collaboration_models.dart';

/// Provider for the [CollaborationRepository].
final collaborationRepositoryProvider =
    Provider<CollaborationRepository>((ref) {
  return CollaborationRepository();
});

/// Repository for managing collaborative learning features like Karma, daily challenges, and study rooms.
class CollaborationRepository {
  final SupabaseClient _client;

  /// Creates a [CollaborationRepository] instance.
  CollaborationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // --- Karma & Scores ---

  /// Awards Karma points to the current user.
  Future<void> awardKarma(int points) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Use RPC or manual update (upsert)
    final current = await getMyScore();
    await _client.from('student_scores').upsert({
      'user_id': userId,
      'karma_points': (current?.karmaPoints ?? 0) + points,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Marks a specific daily challenge as completed and awards reward points.
  Future<void> completeChallenge(String challengeId, int reward) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Award reward points
    await awardKarma(reward);

    // 2. Mark as completed in student_scores
    final current = await getMyScore();
    await _client.from('student_scores').update({
      'challenges_completed': (current?.challengesCompleted ?? 0) + 1,
      'last_challenge_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // --- Daily Challenges ---

  /// Creates a new study room session for a group.
  Future<void> createSession(String groupId, String title) async {
    await _client.from('study_room_sessions').insert({
      'group_id': groupId,
      'title': title,
      'is_live': true,
    });
  }

  /// Retrieves active daily challenges for today.
  Future<List<DailyChallenge>> getActiveChallenges() async {
    final response = await _client
        .from('daily_challenges')
        .select('*')
        .eq('active_date', DateTime.now().toIso8601String().split('T')[0]);

    return (response as List)
        .map((json) => DailyChallenge.fromJson(json))
        .toList();
  }

  // --- Real-time Study Rooms ---

  /// Retrieves the current user's performance score.
  Future<StudentScore?> getMyScore() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('student_scores')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return StudentScore.fromJson(response);
  }

  /// Pins a resource (e.g., link, file) to a study room session.
  Future<void> pinResource(String sessionId, dynamic resource) async {
    // This involves updating the jsonb array in Supabase
    // For simplicity in the demo, we fetch and update
    final session = await _client
        .from('study_room_sessions')
        .select('pinned_resources')
        .eq('id', sessionId)
        .single();
    List<dynamic> pins = List.from(session['pinned_resources'] ?? []);
    pins.add(resource);

    await _client.from('study_room_sessions').update({
      'pinned_resources': pins,
    }).eq('id', sessionId);
  }

  /// Watches for live study room sessions for a specific group.
  Stream<List<StudyRoomSession>> watchLiveSessions(String groupId) {
    return _client
        .from('study_room_sessions')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((data) => data
            .where((json) => json['is_live'] == true)
            .map((json) => StudyRoomSession.fromJson(json))
            .toList());
  }
}
