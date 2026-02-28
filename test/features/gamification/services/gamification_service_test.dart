import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/models/badge_model.dart';
import 'package:verasso/features/gamification/services/gamification_service.dart';

void main() {
  group('GamificationService Tests', () {
    test('calculateLevel should return correct level based on XP', () {
      expect(GamificationService.calculateLevel(0), 1);
      expect(GamificationService.calculateLevel(50), 1);
      expect(GamificationService.calculateLevel(99), 1);
      expect(GamificationService.calculateLevel(100), 2);
      expect(GamificationService.calculateLevel(150), 2);
      expect(GamificationService.calculateLevel(1000), 11);
    });

    group('checkUnlockedBadges', () {
      test('should unlock subject badges when criteria met', () {
        final stats = UserStats(
          userId: 'u1',
          totalXP: 500,
          level: 5,
          unlockedBadges: [],
          currentStreak: 0,
          longestStreak: 0,
          subjectProgress: {'Physics': 12, 'Chemistry': 1},
          lastActive: DateTime.now(),
        );

        final badges = GamificationService.checkUnlockedBadges(stats);

        // Physics:12 unlocks physics_master; totalSims >= 1 unlocks first_steps
        expect(badges.any((b) => b.id == 'physics_master'), isTrue);
        expect(badges.any((b) => b.id == 'first_steps'), isTrue);
      });

      test('should NOT unlock if criteria not met', () {
        final stats = UserStats(
          userId: 'u1',
          totalXP: 500,
          level: 5,
          unlockedBadges: [],
          currentStreak: 0,
          longestStreak: 0,
          subjectProgress: {'Physics': 11},
          lastActive: DateTime.now(),
        );

        final badges = GamificationService.checkUnlockedBadges(stats);

        // first_steps still triggers (totalSims >= 1), but physics_master does NOT
        expect(badges.any((b) => b.id == 'physics_master'), isFalse);
      });

      test('should NOT unlock if already unlocked', () {
        final stats = UserStats(
          userId: 'u1',
          totalXP: 500,
          level: 5,
          unlockedBadges: ['physics_master', 'first_steps'],
          currentStreak: 0,
          longestStreak: 0,
          subjectProgress: {'Physics': 12},
          lastActive: DateTime.now(),
        );

        final badges = GamificationService.checkUnlockedBadges(stats);

        // Both relevant badges already unlocked, so nothing new
        expect(badges.where((b) => b.id == 'physics_master'), isEmpty);
        expect(badges.where((b) => b.id == 'first_steps'), isEmpty);
      });

      test('should unlock streak master badge', () {
        final stats = UserStats(
          userId: 'u1',
          totalXP: 500,
          level: 5,
          unlockedBadges: [],
          currentStreak: 30,
          longestStreak: 30,
          subjectProgress: {},
          lastActive: DateTime.now(),
        );

        final badges = GamificationService.checkUnlockedBadges(stats);

        expect(badges.any((b) => b.id == 'streak_master'), isTrue);
      });
    });

    group('updateStreak', () {
      test('should maintain streak if active same day', () {
        final now = DateTime.now();
        final streak = GamificationService.updateStreak(now, 5);

        expect(streak['currentStreak'], 5);
        expect(streak['broken'], 0);
      });

      test('should increment streak if active next day', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final streak = GamificationService.updateStreak(yesterday, 5);

        expect(streak['currentStreak'], 6);
        expect(streak['broken'], 0);
      });

      test('should reset streak if missed a day', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final streak = GamificationService.updateStreak(twoDaysAgo, 5);

        expect(streak['currentStreak'], 0); // Logic says 0 if broken
        expect(streak['broken'], 1);
      });
    });
  });
}
