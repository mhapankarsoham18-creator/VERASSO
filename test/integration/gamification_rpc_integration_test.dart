import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/gamification_engine.dart';
import 'package:verasso/features/gamification/services/gamification_event_bus.dart';
import 'package:verasso/features/gamification/services/gamification_service.dart';

/// Integration-style tests that verify the gamification subsystems work
/// together correctly. These test pure logic — no Supabase required.
void main() {
  group('XP → Tier → Feature Integration', () {
    test('user progresses through tiers as XP increases', () {
      // Start as bronze
      expect(TierSystem.getTierForXP(0), 'bronze');
      expect(LeaderboardEngine.calculateTier(0), 'Bronze');

      // Reach silver
      expect(TierSystem.getTierForXP(1000), 'silver');
      expect(LeaderboardEngine.calculateTier(1000), 'Silver');

      // Reach gold
      expect(TierSystem.getTierForXP(5000), 'gold');
      expect(LeaderboardEngine.calculateTier(5000), 'Gold');

      // Reach platinum
      expect(TierSystem.getTierForXP(10000), 'platinum');
      expect(LeaderboardEngine.calculateTier(10000), 'Platinum');
    });

    test('features unlock as user earns XP', () {
      // Bronze: no premium features
      expect(TierSystem.hasFeatureUnlocked(500, 'create_guild'), isFalse);
      expect(TierSystem.hasFeatureUnlocked(500, 'advanced_analytics'), isFalse);
      expect(
          TierSystem.hasFeatureUnlocked(500, 'custom_avatar_frame'), isFalse);

      // Silver: guild creation unlocked
      expect(TierSystem.hasFeatureUnlocked(1000, 'create_guild'), isTrue);
      expect(
          TierSystem.hasFeatureUnlocked(1000, 'advanced_analytics'), isFalse);

      // Gold: analytics unlocked
      expect(TierSystem.hasFeatureUnlocked(5000, 'advanced_analytics'), isTrue);
      expect(
          TierSystem.hasFeatureUnlocked(5000, 'custom_avatar_frame'), isFalse);

      // Platinum: everything unlocked
      expect(
          TierSystem.hasFeatureUnlocked(10000, 'custom_avatar_frame'), isTrue);
    });
  });

  group('Activity → XP calculation flow', () {
    test('completing all challenge types gives correct cumulative XP', () {
      final easy = XPRewardEngine.calculateActivityXP('challenge_easy');
      final medium = XPRewardEngine.calculateActivityXP('challenge_medium');
      final hard = XPRewardEngine.calculateActivityXP('challenge_hard');
      final expert = XPRewardEngine.calculateActivityXP('challenge_expert');

      expect(easy, 10);
      expect(medium, 25);
      expect(hard, 50);
      expect(expert, 100);
      expect(easy + medium + hard + expert, 185);
    });

    test('quiz scoring correctly maps to XP brackets', () {
      // Boundary tests for all quiz score brackets
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 69), 0);
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 70), 5);
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 79), 5);
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 80), 8);
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 89), 8);
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 90), 10);
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 99), 10);
      expect(XPRewardEngine.calculateActivityXP('quiz', quizScore: 100), 15);
    });
  });

  group('Event Bus → Action Config consistency', () {
    test('every GamificationAction maps to a consistent config', () {
      // Verify that the event bus action configs are complete and valid
      for (final action in GamificationAction.values) {
        final event = GamificationEvent(action: action, userId: 'integration');
        final config = event.config;

        expect(config.baseXP, greaterThan(0),
            reason: '${action.name} should award positive XP');
        expect(config.dbActionType, isNotEmpty,
            reason: '${action.name} needs a DB action type');
        expect(config.cooldown, isNotNull,
            reason: '${action.name} must have a cooldown defined');
      }
    });

    test('social actions have cooldowns to prevent spam', () {
      const spammableActions = [
        GamificationAction.postCreated,
        GamificationAction.commentWritten,
        GamificationAction.likeGiven,
        GamificationAction.messageSent,
      ];

      for (final action in spammableActions) {
        final event = GamificationEvent(action: action, userId: 'test');
        expect(event.config.cooldown, greaterThan(Duration.zero),
            reason: '${action.name} should have anti-spam cooldown');
      }
    });

    test('learning actions have no cooldown (once per achievement)', () {
      const learningActions = [
        GamificationAction.lessonCompleted,
        GamificationAction.challengeSolved,
        GamificationAction.quizPassed,
        GamificationAction.courseEnrolled,
      ];

      for (final action in learningActions) {
        final event = GamificationEvent(action: action, userId: 'test');
        expect(event.config.cooldown, Duration.zero,
            reason: '${action.name} should have no cooldown');
      }
    });
  });

  group('Level calculation consistency', () {
    test('GamificationService level calculation is monotonically increasing',
        () {
      int previousLevel = 0;
      for (int xp = 0; xp <= 10000; xp += 100) {
        final level = GamificationService.calculateLevel(xp);
        expect(level, greaterThanOrEqualTo(previousLevel),
            reason: 'Level should not decrease as XP increases (at XP=$xp)');
        previousLevel = level;
      }
    });

    test('level 1 starts at 0 XP', () {
      expect(GamificationService.calculateLevel(0), 1);
    });
  });

  group('Badge XP reward values', () {
    test('badge rewards increase with badge difficulty', () {
      final novice = BadgeSystem.badges['novice_coder']!.xpReward;
      final padawan = BadgeSystem.badges['python_padawan']!.xpReward;
      final champion = BadgeSystem.badges['challenge_champion']!.xpReward;
      final codemaster = BadgeSystem.badges['codemaster']!.xpReward;

      expect(novice, lessThan(padawan));
      expect(champion, greaterThan(padawan));
      expect(codemaster, greaterThan(champion));
    });
  });
}
