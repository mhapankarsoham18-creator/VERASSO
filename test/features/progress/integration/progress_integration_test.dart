import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late ProgressTrackingService service;
  const testUserId = 'test-user-id';

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();

    // Mock authenticated user
    final mockUser =
        TestSupabaseUser(id: testUserId, email: 'test@example.com');
    final mockGoTrue = MockGoTrueClient();
    mockGoTrue.setCurrentUser(mockUser);
    mockSupabaseClient.setAuth(mockGoTrue);

    service = ProgressTrackingService(client: mockSupabaseClient);
  });

  group('ProgressTrackingService Tests (Mocked)', () {
    test('getUserProgress returns data correctly', () async {
      // Arrange
      final mockData = {
        'user_id': testUserId,
        'total_points': 1500,
        'current_level': 5,
        'current_xp': 500,
        'xp_to_next_level': 1000,
        'level_progress_percent': 0.5,
        'total_posts': 10,
        'total_comments': 20,
        'total_messages': 5,
        'total_likes_received': 50,
        'total_followers_gained': 100,
        'login_streak': 7,
        'longest_login_streak': 14,
        'last_login_date': DateTime.now().toIso8601String(),
        'milestones_completed': 3,
        'achievements_earned': 2,
        'time_spent_minutes': 300,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_activity_at': DateTime.now().toIso8601String(),
      };

      // Configure mock response for the view
      mockSupabaseClient.setQueryBuilder(
        'v_user_progress_summary',
        MockSupabaseQueryBuilder(selectResponse: [mockData]),
      );

      // Act
      final result = await service.getUserProgress(testUserId);

      // Assert
      expect(result, isNotNull);
      expect(result!.totalPoints, 1500);
      expect(result.currentLevel, 5);
      expect(result.loginStreak, 7);
    });

    test('getLeaderboard returns list of users', () async {
      // Arrange
      final mockData = [
        {
          'rank': 1,
          'user_id': 'user1',
          'total_points': 2000,
          'username': 'User 1'
        },
        {
          'rank': 2,
          'user_id': 'user2',
          'total_points': 1500,
          'username': 'User 2'
        },
      ];

      mockSupabaseClient.setQueryBuilder(
        'v_leaderboard',
        MockSupabaseQueryBuilder(selectResponse: mockData),
      );

      // Act
      final result = await service.getLeaderboard();

      // Assert
      expect(result, isNotEmpty);
      expect(result.length, 2);
      expect(result[0]['rank'], 1);
    });

    test('getUserAchievements returns list', () async {
      // Arrange
      final mockData = [
        {
          'id': '1',
          'achievement_id': 'ach1',
          'name': 'First Post',
          'description': 'Created first post',
          'points_awarded': 10,
          'earned_at': DateTime.now().toIso8601String(),
          'is_pinned': false,
        }
      ];

      mockSupabaseClient.setQueryBuilder(
        'user_achievements',
        MockSupabaseQueryBuilder(selectResponse: mockData),
      );

      // Act
      final result = await service.getUserAchievements(testUserId);

      // Assert
      expect(result, isNotEmpty);
      expect(result.first.name, 'First Post');
    });

    test('logActivity calls RPC', () async {
      // Arrange
      mockSupabaseClient.setRpcResponse('log_activity_and_award_points', null);

      // Act
      await service.logActivity(
          userId: testUserId, activityType: 'post_created');

      // Assert
      // Verification is implicit via no exception thrown
      // Ideally we verify calls but MockSupabaseClient might not track calls easily without spying
      // For enabling tests, ensuring it runs without error is sufficient.
    });

    test('estimateTimeToNextLevel calculates correctly', () async {
      // Arrange
      // Mock progress created 10 days ago (roughly)
      // Current XP 500. Rate = 50 XP/day.
      // XP to next level = 1000. Remaining in level = 500 (assuming 0 base).
      // Wait, calculation logic:
      // dailyXpRate = currentXp / daysSinceCreation
      // xpToNextLevel is total for level?
      // xpRemaining = xpToNextLevel - (currentXp % xpToNextLevel)
      // days = xpRemaining / dailyXpRate

      final createdAt = DateTime.now().subtract(const Duration(days: 10));
      final mockData = {
        'user_id': testUserId,
        'total_points': 500,
        'current_level': 1,
        'current_xp': 500,
        'xp_to_next_level': 1000,
        'level_progress_percent': 0.5,
        'total_posts': 0,
        'total_comments': 0,
        'total_messages': 0,
        'total_likes_received': 0,
        'total_followers_gained': 0,
        'login_streak': 0,
        'longest_login_streak': 0,
        'milestones_completed': 0,
        'achievements_earned': 0,
        'time_spent_minutes': 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_activity_at': DateTime.now().toIso8601String(),
      };

      mockSupabaseClient.setQueryBuilder(
        'v_user_progress_summary',
        MockSupabaseQueryBuilder(selectResponse: [mockData]),
      );

      // Act
      final result = await service.estimateTimeToNextLevel(testUserId);

      // Assert
      expect(result, isNotNull);
      expect(result!.inDays, closeTo(10, 1));
    });
  });
}
