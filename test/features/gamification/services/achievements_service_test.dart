import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/services/achievements_service.dart';

import '../../../mocks.dart';

void main() {
  late AchievementsService achievementsService;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    achievementsService = AchievementsService(mockSupabase);
  });

  group('AchievementsService', () {
    test('getAllAchievements returns list on success', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder(
        selectResponse: [
          {
            'id': '1',
            'name': 'Test',
            'description': 'Desc',
            'category': 'learning',
            'requirement_type': 'xp',
            'requirement_value': 100,
            'points_reward': 50,
            'rarity': 'common',
            'is_active': true,
          }
        ],
      );

      mockSupabase.setQueryBuilder('achievements', mockQueryBuilder);

      final result = await achievementsService.getAllAchievements();
      expect(result.length, 1);
      expect(result.first.name, 'Test');
    });

    test('getAllAchievements throws DatabaseException on failure', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('achievements', mockQueryBuilder);

      expect(() => achievementsService.getAllAchievements(),
          throwsA(isA<DatabaseException>()));
    });

    test('getMyRank returns rank on success', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder(
        selectResponse: {'rank': 10},
      );
      mockSupabase.setQueryBuilder('user_stats', mockQueryBuilder);

      final rank = await achievementsService.getMyRank();
      expect(rank, 10);
    });
  });
}
