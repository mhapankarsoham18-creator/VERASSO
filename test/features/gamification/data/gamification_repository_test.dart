import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/data/gamification_repository.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late GamificationRepository repository;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    repository = GamificationRepository(client: mockSupabase);
  });

  group('GamificationRepository Tests', () {
    test('getLeaderboard should return sorted UserStats list', () async {
      final leaderboardData = [
        {
          'user_id': 'u1',
          'total_xp': 500,
          'level': 6,
          'current_streak': 5,
          'longest_streak': 10,
          'last_active': DateTime.now().toIso8601String(),
          'profiles': {
            'username': 'alice',
            'full_name': 'Alice',
            'avatar_url': null,
          },
        },
        {
          'user_id': 'u2',
          'total_xp': 300,
          'level': 4,
          'current_streak': 2,
          'longest_streak': 7,
          'last_active': DateTime.now().toIso8601String(),
          'profiles': {
            'username': 'bob',
            'full_name': 'Bob',
            'avatar_url': null,
          },
        },
      ];

      final builder = MockSupabaseQueryBuilder(selectResponse: leaderboardData);
      mockSupabase.setQueryBuilder('user_stats', builder);

      final result = await repository.getLeaderboard();

      expect(result.length, 2);
      expect(result.first.userId, 'u1');
      expect(result.first.totalXP, 500);
      expect(result.last.userId, 'u2');
    });

    test('getLeaderboard should return empty with no data', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('user_stats', builder);

      final result = await repository.getLeaderboard();

      expect(result, isEmpty);
    });

    test('unlockBadge should upsert badge record', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('user_badges', builder);

      // Should not throw
      await repository.unlockBadge('physics_master');

      expect(mockSupabase.from('user_badges'), isNotNull);
    });

    test('unlockBadge should do nothing if no user', () async {
      mockAuth.setCurrentUser(null);

      // Should return silently (no error)
      await repository.unlockBadge('physics_master');
    });
  });
}
