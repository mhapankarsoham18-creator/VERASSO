import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/models/badge_model.dart';
import 'package:verasso/features/gamification/services/gamification_service.dart';

void main() {
  group('GamificationService', () {
    test('calculateLevel returns correct level based on XP', () {
      expect(GamificationService.calculateLevel(0), 1);
      expect(GamificationService.calculateLevel(99), 1);
      expect(GamificationService.calculateLevel(100), 2);
      expect(GamificationService.calculateLevel(400), 5);
    });

    test('calculateSimulationXP returns standard base XP', () {
      expect(GamificationService.calculateSimulationXP('any_sim'), 100);
    });

    test('checkUnlockedBadges awards physics_master at 12 simulations', () {
      final stats = UserStats(
        userId: 'test_user',
        totalXP: 1200,
        level: 13,
        unlockedBadges: [],
        subjectProgress: {'Physics': 12},
        currentStreak: 0,
        longestStreak: 0,
        lastActive: DateTime.now(),
      );

      final badges = GamificationService.checkUnlockedBadges(stats);
      expect(badges.any((b) => b.id == 'physics_master'), isTrue);
    });

    test('checkUnlockedBadges awards streak_master at 30 days', () {
      final stats = UserStats(
        userId: 'test_user',
        totalXP: 0,
        level: 1,
        unlockedBadges: [],
        subjectProgress: {},
        currentStreak: 30,
        longestStreak: 30,
        lastActive: DateTime.now(),
      );

      final badges = GamificationService.checkUnlockedBadges(stats);
      expect(badges.any((b) => b.id == 'streak_master'), isTrue);
    });

    test('updateStreak correctly increments on daily activity', () {
      final lastActive = DateTime.now().subtract(const Duration(days: 1));
      final result = GamificationService.updateStreak(lastActive, 5);

      expect(result['currentStreak'], 6);
      expect(result['broken'], 0);
    });

    test('updateStreak resets on inactivity', () {
      final lastActive = DateTime.now().subtract(const Duration(days: 2));
      final result = GamificationService.updateStreak(lastActive, 5);

      expect(result['currentStreak'], 0);
      expect(result['broken'], 1);
    });
  });
}
