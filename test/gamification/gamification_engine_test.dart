import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/gamification_engine.dart';

/// Tests for the gamification engine: XP rewards, badge requirements,
/// tier system, and streak calculations.
///
/// These test the pure calculation logic in the gamification engine
/// without requiring Supabase connections.
void main() {
  group('XPRewardEngine', () {
    group('calculateActivityXP', () {
      test('returns correct XP for lesson_complete', () {
        expect(XPRewardEngine.calculateActivityXP('lesson_complete'), 5);
      });

      test('returns correct XP for module_complete', () {
        expect(XPRewardEngine.calculateActivityXP('module_complete'), 50);
      });

      test('returns correct XP for challenge_easy', () {
        expect(XPRewardEngine.calculateActivityXP('challenge_easy'), 10);
      });

      test('returns correct XP for challenge_medium', () {
        expect(XPRewardEngine.calculateActivityXP('challenge_medium'), 25);
      });

      test('returns correct XP for challenge_hard', () {
        expect(XPRewardEngine.calculateActivityXP('challenge_hard'), 50);
      });

      test('returns correct XP for challenge_expert', () {
        expect(XPRewardEngine.calculateActivityXP('challenge_expert'), 100);
      });

      test('returns 0 for unknown activity', () {
        expect(XPRewardEngine.calculateActivityXP('nonexistent'), 0);
      });

      test('returns correct XP for perfect quiz', () {
        expect(
          XPRewardEngine.calculateActivityXP('quiz', quizScore: 100),
          15,
        );
      });

      test('returns correct XP for 90-99 quiz', () {
        expect(
          XPRewardEngine.calculateActivityXP('quiz', quizScore: 95),
          10,
        );
      });

      test('returns correct XP for 80-89 quiz', () {
        expect(
          XPRewardEngine.calculateActivityXP('quiz', quizScore: 85),
          8,
        );
      });

      test('returns correct XP for 70-79 quiz', () {
        expect(
          XPRewardEngine.calculateActivityXP('quiz', quizScore: 75),
          5,
        );
      });

      test('returns 0 for quiz below 70', () {
        expect(
          XPRewardEngine.calculateActivityXP('quiz', quizScore: 65),
          0,
        );
      });

      test('returns 0 for quiz with null score', () {
        expect(
          XPRewardEngine.calculateActivityXP('quiz'),
          0,
        );
      });
    });

    group('getGlobalMultiplier', () {
      test('returns a valid multiplier', () {
        final multiplier = XPRewardEngine.getGlobalMultiplier();
        expect(multiplier, anyOf(1.0, 1.5));
      });

      test('returns 1.0 or 1.5 (no other values)', () {
        final multiplier = XPRewardEngine.getGlobalMultiplier();
        expect(multiplier == 1.0 || multiplier == 1.5, isTrue);
      });
    });

    group('hintCost', () {
      test('hint_used deducts 2 XP', () {
        expect(XPRewardEngine.hintCost['hint_used'], -2);
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

      test('returns Silver for 1000 <= XP < 5000', () {
        expect(LeaderboardEngine.calculateTier(1000), 'Silver');
        expect(LeaderboardEngine.calculateTier(2500), 'Silver');
        expect(LeaderboardEngine.calculateTier(4999), 'Silver');
      });

      test('returns Gold for 5000 <= XP < 10000', () {
        expect(LeaderboardEngine.calculateTier(5000), 'Gold');
        expect(LeaderboardEngine.calculateTier(7500), 'Gold');
        expect(LeaderboardEngine.calculateTier(9999), 'Gold');
      });

      test('returns Platinum for XP >= 10000', () {
        expect(LeaderboardEngine.calculateTier(10000), 'Platinum');
        expect(LeaderboardEngine.calculateTier(50000), 'Platinum');
        expect(LeaderboardEngine.calculateTier(999999), 'Platinum');
      });
    });
  });

  group('TierSystem', () {
    group('getTierForXP', () {
      test('returns bronze for XP < 1000', () {
        expect(TierSystem.getTierForXP(0), 'bronze');
        expect(TierSystem.getTierForXP(999), 'bronze');
      });

      test('returns silver for 1000 <= XP < 5000', () {
        expect(TierSystem.getTierForXP(1000), 'silver');
        expect(TierSystem.getTierForXP(4999), 'silver');
      });

      test('returns gold for 5000 <= XP < 10000', () {
        expect(TierSystem.getTierForXP(5000), 'gold');
        expect(TierSystem.getTierForXP(9999), 'gold');
      });

      test('returns platinum for XP >= 10000', () {
        expect(TierSystem.getTierForXP(10000), 'platinum');
      });
    });

    group('getProgressPercentage', () {
      test('returns 0 at tier start', () {
        expect(TierSystem.getProgressPercentage(0), 0);
      });

      test('returns ~50 at tier midpoint', () {
        // Bronze: 0-999 (1000 range), midpoint ~500
        final progress = TierSystem.getProgressPercentage(500);
        expect(progress, closeTo(50, 5)); // Allow ±5% tolerance
      });

      test('returns high value near tier end', () {
        final progress = TierSystem.getProgressPercentage(999);
        expect(progress, greaterThan(90));
      });

      test('returns 0 at silver tier start', () {
        expect(TierSystem.getProgressPercentage(1000), 0);
      });
    });

    group('hasFeatureUnlocked', () {
      test('guild creation requires Silver (1000 XP)', () {
        expect(TierSystem.hasFeatureUnlocked(999, 'create_guild'), isFalse);
        expect(TierSystem.hasFeatureUnlocked(1000, 'create_guild'), isTrue);
      });

      test('advanced analytics requires Gold (5000 XP)', () {
        expect(
          TierSystem.hasFeatureUnlocked(4999, 'advanced_analytics'),
          isFalse,
        );
        expect(
          TierSystem.hasFeatureUnlocked(5000, 'advanced_analytics'),
          isTrue,
        );
      });

      test('custom avatar frame requires Platinum (10000 XP)', () {
        expect(
          TierSystem.hasFeatureUnlocked(9999, 'custom_avatar_frame'),
          isFalse,
        );
        expect(
          TierSystem.hasFeatureUnlocked(10000, 'custom_avatar_frame'),
          isTrue,
        );
      });

      test('unknown feature is always unlocked', () {
        expect(TierSystem.hasFeatureUnlocked(0, 'unknown_feature'), isTrue);
      });
    });

    group('tiers definition', () {
      test('all tiers are defined', () {
        expect(TierSystem.tiers.containsKey('bronze'), isTrue);
        expect(TierSystem.tiers.containsKey('silver'), isTrue);
        expect(TierSystem.tiers.containsKey('gold'), isTrue);
        expect(TierSystem.tiers.containsKey('platinum'), isTrue);
      });

      test('tier XP ranges do not overlap', () {
        final bronze = TierSystem.tiers['bronze']!;
        final silver = TierSystem.tiers['silver']!;
        final gold = TierSystem.tiers['gold']!;
        final platinum = TierSystem.tiers['platinum']!;

        expect(bronze.maxXP, lessThan(silver.minXP));
        expect(silver.maxXP, lessThan(gold.minXP));
        expect(gold.maxXP, lessThan(platinum.minXP));
      });
    });
  });

  group('BadgeSystem', () {
    group('badge definitions', () {
      test('all expected badges exist', () {
        expect(BadgeSystem.badges.containsKey('novice_coder'), isTrue);
        expect(BadgeSystem.badges.containsKey('python_padawan'), isTrue);
        expect(BadgeSystem.badges.containsKey('function_master'), isTrue);
        expect(BadgeSystem.badges.containsKey('challenge_champion'), isTrue);
        expect(BadgeSystem.badges.containsKey('codemaster'), isTrue);
      });

      test('all badges have positive XP rewards', () {
        for (final badge in BadgeSystem.badges.values) {
          expect(badge.xpReward, greaterThan(0),
              reason: 'Badge ${badge.id} should have positive XP reward');
        }
      });

      test('all badges have non-empty titles', () {
        for (final badge in BadgeSystem.badges.values) {
          expect(badge.title.isNotEmpty, isTrue);
        }
      });

      test('all badges have icon paths', () {
        for (final badge in BadgeSystem.badges.values) {
          expect(badge.icon, startsWith('assets/'));
        }
      });
    });

    group('badge requirements', () {
      test('novice_coder requires at least 1 lesson completed', () {
        final badge = BadgeSystem.badges['novice_coder']!;
        expect(badge.requirement({'lessons_completed': 0}), isFalse);
        expect(badge.requirement({'lessons_completed': 1}), isTrue);
        expect(badge.requirement({'lessons_completed': 5}), isTrue);
      });

      test('novice_coder handles missing data', () {
        final badge = BadgeSystem.badges['novice_coder']!;
        expect(badge.requirement({}), isFalse);
      });

      test('python_padawan requires module 1 completed', () {
        final badge = BadgeSystem.badges['python_padawan']!;
        expect(badge.requirement({'modules_completed': []}), isFalse);
        expect(badge.requirement({'modules_completed': [1]}), isTrue);
        expect(badge.requirement({'modules_completed': [2]}), isFalse);
        expect(badge.requirement({'modules_completed': [1, 2]}), isTrue);
      });

      test('function_master requires module 2 completed', () {
        final badge = BadgeSystem.badges['function_master']!;
        expect(badge.requirement({'modules_completed': [1]}), isFalse);
        expect(badge.requirement({'modules_completed': [2]}), isTrue);
      });

      test('challenge_champion requires 30 challenges solved', () {
        final badge = BadgeSystem.badges['challenge_champion']!;
        expect(badge.requirement({'challenges_solved': 29}), isFalse);
        expect(badge.requirement({'challenges_solved': 30}), isTrue);
        expect(badge.requirement({'challenges_solved': 50}), isTrue);
      });

      test('codemaster requires all modules, 61 challenges, 8 quizzes', () {
        final badge = BadgeSystem.badges['codemaster']!;

        // Missing everything
        expect(badge.requirement({}), isFalse);

        // Partial completion
        expect(
          badge.requirement({
            'modules_completed': [1, 2, 3, 4, 5, 6, 7, 8],
            'challenges_solved': 60,
            'quizzes_completed': 8,
          }),
          isFalse,
        );

        // Full completion
        expect(
          badge.requirement({
            'modules_completed': [1, 2, 3, 4, 5, 6, 7, 8],
            'challenges_solved': 61,
            'quizzes_completed': 8,
          }),
          isTrue,
        );
      });
    });
  });

  group('XP Activity Rewards Completeness', () {
    test('all expected activity types have rewards', () {
      final expectedActivities = [
        'lesson_complete',
        'module_complete',
        'challenge_easy',
        'challenge_medium',
        'challenge_hard',
        'challenge_expert',
        'quiz_70_79',
        'quiz_80_89',
        'quiz_90_99',
        'quiz_100',
        'first_lesson',
        'streak_5day',
        'leaderboard_top10',
        'challenge_solved_30',
        'all_challenges_solved',
      ];

      for (final activity in expectedActivities) {
        expect(
          XPRewardEngine.activityRewards.containsKey(activity),
          isTrue,
          reason: 'Missing reward for: $activity',
        );
      }
    });

    test('all rewards are positive integers', () {
      for (final entry in XPRewardEngine.activityRewards.entries) {
        expect(
          entry.value,
          greaterThan(0),
          reason: '${entry.key} should have positive XP reward',
        );
      }
    });

    test('harder challenges give more XP', () {
      expect(
        XPRewardEngine.activityRewards['challenge_easy']!,
        lessThan(XPRewardEngine.activityRewards['challenge_medium']!),
      );
      expect(
        XPRewardEngine.activityRewards['challenge_medium']!,
        lessThan(XPRewardEngine.activityRewards['challenge_hard']!),
      );
      expect(
        XPRewardEngine.activityRewards['challenge_hard']!,
        lessThan(XPRewardEngine.activityRewards['challenge_expert']!),
      );
    });

    test('higher quiz scores give more XP', () {
      expect(
        XPRewardEngine.activityRewards['quiz_70_79']!,
        lessThan(XPRewardEngine.activityRewards['quiz_80_89']!),
      );
      expect(
        XPRewardEngine.activityRewards['quiz_80_89']!,
        lessThan(XPRewardEngine.activityRewards['quiz_90_99']!),
      );
      expect(
        XPRewardEngine.activityRewards['quiz_90_99']!,
        lessThan(XPRewardEngine.activityRewards['quiz_100']!),
      );
    });
  });
}
