import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/services/seasonal_challenge_service.dart';

import '../../../mocks.dart';

void main() {
  late SeasonalChallengeService seasonalService;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    seasonalService = SeasonalChallengeService(client: mockSupabase);
  });

  group('SeasonalChallengeService', () {
    test('getActiveEvents calls RPC and returns list', () async {
      mockSupabase.setRpcResponse('get_active_seasonal_events_with_rewards', [
        {
          'event_id': 'event-1',
          'title': 'Winter Challenge',
          'start_at': DateTime.now().toIso8601String(),
          'end_at':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'rewards': [
            {'id': 'reward-1', 'xp_bonus': 500}
          ]
        }
      ]);

      final events = await seasonalService.getActiveEvents();
      expect(events.length, 1);
      expect(events.first.title, 'Winter Challenge');
      expect(events.first.rewards.first.xpBonus, 500);
    });

    test('checkEventCompletion calls RPC', () async {
      final mockAuth = MockGoTrueClient();
      final mockUser = TestSupabaseUser(id: 'user-123');
      mockAuth.setCurrentUser(mockUser);
      mockSupabase.setAuth(mockAuth);

      mockSupabase.setRpcResponse('check_seasonal_event_completion', null);

      await seasonalService.checkEventCompletion('event-1');

      expect(mockSupabase.lastRpcName, 'check_seasonal_event_completion');
    });
  });
}
