import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/models/badge_model.dart';
import 'package:verasso/features/gamification/services/gamification_service.dart';

void main() {
  group('GamificationService', () {
    group('calculateLevel', () {
      test('returns level 1 for 0 XP', () {
        final level = GamificationService.calculateLevel(0);
        expect(level, 1);
      });

      test('returns level 1 for 99 XP', () {
        final level = GamificationService.calculateLevel(99);
        expect(level, 1);
      });

      test('returns level 2 for 100 XP', () {
        final level = GamificationService.calculateLevel(100);
        expect(level, 2);
      });

      test('returns level 5 for 400 XP', () {
        final level = GamificationService.calculateLevel(400);
        expect(level, 5);
      });

      test('handles large XP values', () {
        final level = GamificationService.calculateLevel(100000);
        expect(level, greaterThanOrEqualTo(10));
      });
    });

    group('updateStreak', () {
      test('same day does not change streak', () {
        final result = GamificationService.updateStreak(DateTime.now(), 5);
        expect(result['currentStreak'], 5);
        expect(result['broken'], 0);
      });

      test('next day increments streak', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = GamificationService.updateStreak(yesterday, 5);
        expect(result['currentStreak'], 6);
        expect(result['broken'], 0);
      });

      test('two+ days gap breaks streak', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final result = GamificationService.updateStreak(twoDaysAgo, 5);
        expect(result['currentStreak'], 0);
        expect(result['broken'], 1);
      });
    });

    group('getBadgeColor', () {
      test('common returns gray', () {
        expect(
            GamificationService.getBadgeColor(BadgeRarity.common), '#9E9E9E');
      });

      test('rare returns blue', () {
        expect(GamificationService.getBadgeColor(BadgeRarity.rare), '#2196F3');
      });

      test('epic returns purple', () {
        expect(GamificationService.getBadgeColor(BadgeRarity.epic), '#9C27B0');
      });

      test('legendary returns orange', () {
        expect(GamificationService.getBadgeColor(BadgeRarity.legendary),
            '#FF9800');
      });
    });

    group('getLeaderboard', () {
      test('returns empty list for empty input', () {
        final result = GamificationService.getLeaderboard([]);
        expect(result, isEmpty);
      });

      test('sorts by XP descending', () {
        final users = [
          UserStats(
            userId: 'aaaaaa-1111-2222-3333-444444444444',
            totalXP: 500,
            level: 5,
            currentStreak: 0,
            longestStreak: 0,
            unlockedBadges: [],
            subjectProgress: {},
            lastActive: DateTime.now(),
          ),
          UserStats(
            userId: 'bbbbbb-1111-2222-3333-444444444444',
            totalXP: 1000,
            level: 10,
            currentStreak: 0,
            longestStreak: 0,
            unlockedBadges: [],
            subjectProgress: {},
            lastActive: DateTime.now(),
          ),
        ];
        final result = GamificationService.getLeaderboard(users);
        expect(result.length, 2);
        expect(result[0].userId, 'bbbbbb-1111-2222-3333-444444444444');
        expect(result[1].userId, 'aaaaaa-1111-2222-3333-444444444444');
      });

      test('assigns correct ranks', () {
        final users = [
          UserStats(
            userId: 'aaaaaa-1111-2222-3333-444444444444',
            totalXP: 200,
            level: 2,
            currentStreak: 0,
            longestStreak: 0,
            unlockedBadges: [],
            subjectProgress: {},
            lastActive: DateTime.now(),
          ),
          UserStats(
            userId: 'bbbbbb-1111-2222-3333-444444444444',
            totalXP: 300,
            level: 3,
            currentStreak: 0,
            longestStreak: 0,
            unlockedBadges: [],
            subjectProgress: {},
            lastActive: DateTime.now(),
          ),
        ];
        final result = GamificationService.getLeaderboard(users);
        expect(result[0].rank, 1);
        expect(result[1].rank, 2);
      });
    });

    group('checkUnlockedBadges', () {
      test('unlocks first_steps badge after 1 simulation', () {
        final stats = UserStats(
          userId: 'user_1',
          totalXP: 100,
          level: 2,
          currentStreak: 0,
          longestStreak: 0,
          unlockedBadges: [],
          subjectProgress: {'Physics': 1},
          lastActive: DateTime.now(),
        );

        final result = GamificationService.checkUnlockedBadges(stats);
        final badgeIds = result.map((b) => b.id).toList();
        expect(badgeIds, contains('first_steps'));
      });

      test('does not unlock already unlocked badge', () {
        final stats = UserStats(
          userId: 'user_1',
          totalXP: 100,
          level: 2,
          currentStreak: 0,
          longestStreak: 0,
          unlockedBadges: ['first_steps'],
          subjectProgress: {'Physics': 1},
          lastActive: DateTime.now(),
        );

        final result = GamificationService.checkUnlockedBadges(stats);
        final badgeIds = result.map((b) => b.id).toList();
        expect(badgeIds, isNot(contains('first_steps')));
      });
    });
  });
}
