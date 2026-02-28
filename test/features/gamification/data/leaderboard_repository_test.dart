import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/data/leaderboard_entry_model.dart';
import 'package:verasso/features/gamification/data/leaderboard_repository.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late LeaderboardRepository repository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    repository = LeaderboardRepository(mockSupabase);
  });

  group('LeaderboardRepository Tests', () {
    final entryData = [
      {
        'user_id': 'u1',
        'full_name': 'Alice',
        'avatar_url': null,
        'score': 1200,
        'rank': 1,
      },
      {
        'user_id': 'u2',
        'full_name': 'Bob',
        'avatar_url': 'https://example.com/bob.png',
        'score': 900,
        'rank': 2,
      },
    ];

    test('getTopStudents should return leaderboard entries', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: entryData);
      mockSupabase.setQueryBuilder('view_top_students', builder);

      final result = await repository.getTopStudents();

      expect(result.length, 2);
      expect(result.first.username, 'Alice');
      expect(result.first.score, 1200);
      expect(result.last.rank, 2);
    });

    test('getTopMentors should return leaderboard entries', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: entryData);
      mockSupabase.setQueryBuilder('view_top_mentors', builder);

      final result = await repository.getTopMentors();

      expect(result.length, 2);
      expect(result.first.userId, 'u1');
    });

    test('getChallengeChampions should return leaderboard entries', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: entryData);
      mockSupabase.setQueryBuilder('view_challenge_champions', builder);

      final result = await repository.getChallengeChampions();

      expect(result.length, 2);
      expect(result.last.username, 'Bob');
    });

    test('getTopStudents should return empty with no data', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('view_top_students', builder);

      final result = await repository.getTopStudents();

      expect(result, isEmpty);
    });

    test('LeaderboardEntry.fromJson handles missing fields', () {
      final entry = LeaderboardEntry.fromJson({
        'user_id': 'u3',
      });

      expect(entry.username, 'Anonymous');
      expect(entry.score, 0);
      expect(entry.rank, 0);
    });
  });
}
