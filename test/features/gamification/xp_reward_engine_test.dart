import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/gamification_engine.dart';

void main() {
  group('XPRewardEngine', () {
    group('activityRewards', () {
      test('contains all lesson activities', () {
        expect(XPRewardEngine.activityRewards.containsKey('lesson_complete'),
            isTrue);
        expect(XPRewardEngine.activityRewards.containsKey('module_complete'),
            isTrue);
      });

      test('contains all challenge tiers', () {
        expect(XPRewardEngine.activityRewards['challenge_easy'], 10);
        expect(XPRewardEngine.activityRewards['challenge_medium'], 25);
        expect(XPRewardEngine.activityRewards['challenge_hard'], 50);
        expect(XPRewardEngine.activityRewards['challenge_expert'], 100);
      });

      test('contains quiz score brackets', () {
        expect(XPRewardEngine.activityRewards['quiz_70_79'], 5);
        expect(XPRewardEngine.activityRewards['quiz_80_89'], 8);
        expect(XPRewardEngine.activityRewards['quiz_90_99'], 10);
        expect(XPRewardEngine.activityRewards['quiz_100'], 15);
      });

      test('contains achievement rewards', () {
        expect(XPRewardEngine.activityRewards['first_lesson'], 20);
        expect(XPRewardEngine.activityRewards['streak_5day'], 25);
        expect(XPRewardEngine.activityRewards['leaderboard_top10'], 75);
        expect(XPRewardEngine.activityRewards['challenge_solved_30'], 150);
        expect(XPRewardEngine.activityRewards['all_challenges_solved'], 200);
      });
    });

    group('hintCost', () {
      test('hint deducts 2 XP', () {
        expect(XPRewardEngine.hintCost['hint_used'], -2);
      });
    });

    group('calculateActivityXP', () {
      test('returns correct XP for lesson_complete', () {
        expect(
          XPRewardEngine.calculateActivityXP('lesson_complete'),
          5,
        );
      });

      test('returns correct XP for module_complete', () {
        expect(
          XPRewardEngine.calculateActivityXP('module_complete'),
          50,
        );
      });

      test('returns 0 for unknown activity type', () {
        expect(
          XPRewardEngine.calculateActivityXP('nonexistent_activity'),
          0,
        );
      });

      group('quiz scoring', () {
        test('quiz with score 100 returns quiz_100 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 100),
            15,
          );
        });

        test('quiz with score 95 returns quiz_90_99 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 95),
            10,
          );
        });

        test('quiz with score 85 returns quiz_80_89 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 85),
            8,
          );
        });

        test('quiz with score 75 returns quiz_70_79 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 75),
            5,
          );
        });

        test('quiz with score below 70 returns 0 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 65),
            0,
          );
        });

        test('quiz with null score returns 0 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz'),
            0,
          );
        });

        test('quiz with score exactly 90 returns quiz_90_99 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 90),
            10,
          );
        });

        test('quiz with score exactly 80 returns quiz_80_89 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 80),
            8,
          );
        });

        test('quiz with score exactly 70 returns quiz_70_79 XP', () {
          expect(
            XPRewardEngine.calculateActivityXP('quiz', quizScore: 70),
            5,
          );
        });
      });
    });

    group('getGlobalMultiplier', () {
      test('returns a positive multiplier', () {
        final multiplier = XPRewardEngine.getGlobalMultiplier();
        expect(multiplier, greaterThan(0));
      });

      test('returns either 1.0 or 1.5', () {
        final multiplier = XPRewardEngine.getGlobalMultiplier();
        expect(multiplier, anyOf(equals(1.0), equals(1.5)));
      });
    });
  });

  group('LeaderboardEngine', () {
    group('calculateTier', () {
      test('returns Bronze for XP < 1000', () {
        expect(LeaderboardEngine.calculateTier(0), 'Bronze');
        expect(LeaderboardEngine.calculateTier(500), 'Bronze');
        expect(LeaderboardEngine.calculateTier(999), 'Bronze');
      });

      test('returns Silver for XP 1000-4999', () {
        expect(LeaderboardEngine.calculateTier(1000), 'Silver');
        expect(LeaderboardEngine.calculateTier(3000), 'Silver');
        expect(LeaderboardEngine.calculateTier(4999), 'Silver');
      });

      test('returns Gold for XP 5000-9999', () {
        expect(LeaderboardEngine.calculateTier(5000), 'Gold');
        expect(LeaderboardEngine.calculateTier(7500), 'Gold');
        expect(LeaderboardEngine.calculateTier(9999), 'Gold');
      });

      test('returns Platinum for XP >= 10000', () {
        expect(LeaderboardEngine.calculateTier(10000), 'Platinum');
        expect(LeaderboardEngine.calculateTier(50000), 'Platinum');
      });
    });
  });

  group('TierSystem', () {
    group('getTierForXP', () {
      test('returns bronze for XP < 1000', () {
        expect(TierSystem.getTierForXP(0), 'bronze');
        expect(TierSystem.getTierForXP(999), 'bronze');
      });

      test('returns silver for XP 1000-4999', () {
        expect(TierSystem.getTierForXP(1000), 'silver');
        expect(TierSystem.getTierForXP(4999), 'silver');
      });

      test('returns gold for XP 5000-9999', () {
        expect(TierSystem.getTierForXP(5000), 'gold');
        expect(TierSystem.getTierForXP(9999), 'gold');
      });

      test('returns platinum for XP >= 10000', () {
        expect(TierSystem.getTierForXP(10000), 'platinum');
        expect(TierSystem.getTierForXP(100000), 'platinum');
      });
    });

    group('getProgressPercentage', () {
      test('returns 0 for minimum XP in tier', () {
        expect(TierSystem.getProgressPercentage(0), 0);
      });

      test('returns clamped percentage within bronze tier', () {
        final progress = TierSystem.getProgressPercentage(500);
        expect(progress, greaterThanOrEqualTo(0));
        expect(progress, lessThanOrEqualTo(100));
      });

      test('returns 0 at start of silver tier', () {
        expect(TierSystem.getProgressPercentage(1000), 0);
      });

      test('returns value within range for mid-tier XP', () {
        final progress = TierSystem.getProgressPercentage(2500);
        expect(progress, greaterThan(0));
        expect(progress, lessThan(100));
      });
    });

    group('hasFeatureUnlocked', () {
      test('create_guild requires Silver (1000 XP)', () {
        expect(TierSystem.hasFeatureUnlocked(999, 'create_guild'), isFalse);
        expect(TierSystem.hasFeatureUnlocked(1000, 'create_guild'), isTrue);
      });

      test('advanced_analytics requires Gold (5000 XP)', () {
        expect(
            TierSystem.hasFeatureUnlocked(4999, 'advanced_analytics'), isFalse);
        expect(
            TierSystem.hasFeatureUnlocked(5000, 'advanced_analytics'), isTrue);
      });

      test('custom_avatar_frame requires Platinum (10000 XP)', () {
        expect(TierSystem.hasFeatureUnlocked(9999, 'custom_avatar_frame'),
            isFalse);
        expect(TierSystem.hasFeatureUnlocked(10000, 'custom_avatar_frame'),
            isTrue);
      });

      test('unknown feature is always unlocked', () {
        expect(TierSystem.hasFeatureUnlocked(0, 'unknown_feature_key'), isTrue);
      });
    });

    group('tiers', () {
      test('contains all 4 tiers', () {
        expect(TierSystem.tiers.length, 4);
        expect(TierSystem.tiers.containsKey('bronze'), isTrue);
        expect(TierSystem.tiers.containsKey('silver'), isTrue);
        expect(TierSystem.tiers.containsKey('gold'), isTrue);
        expect(TierSystem.tiers.containsKey('platinum'), isTrue);
      });

      test('tier XP ranges are contiguous', () {
        final bronze = TierSystem.tiers['bronze']!;
        final silver = TierSystem.tiers['silver']!;
        final gold = TierSystem.tiers['gold']!;

        expect(silver.minXP, bronze.maxXP + 1);
        expect(gold.minXP, silver.maxXP + 1);
      });

      test('each tier has a name, color, and icon', () {
        for (final tier in TierSystem.tiers.values) {
          expect(tier.name, isNotEmpty);
          expect(tier.icon, isNotEmpty);
        }
      });
    });
  });
}
