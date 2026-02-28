import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/services/gamification_event_bus.dart';

void main() {
  group('GamificationAction', () {
    test('has all expected action types', () {
      expect(GamificationAction.values.length, 16);
    });

    test('includes social actions', () {
      expect(
          GamificationAction.values, contains(GamificationAction.postCreated));
      expect(GamificationAction.values,
          contains(GamificationAction.commentWritten));
      expect(GamificationAction.values, contains(GamificationAction.likeGiven));
      expect(
          GamificationAction.values, contains(GamificationAction.messageSent));
    });

    test('includes learning actions', () {
      expect(GamificationAction.values,
          contains(GamificationAction.lessonCompleted));
      expect(GamificationAction.values,
          contains(GamificationAction.challengeSolved));
      expect(
          GamificationAction.values, contains(GamificationAction.quizPassed));
      expect(GamificationAction.values,
          contains(GamificationAction.courseEnrolled));
    });

    test('includes other actions', () {
      expect(GamificationAction.values,
          contains(GamificationAction.streakMaintained));
      expect(
          GamificationAction.values, contains(GamificationAction.talentListed));
      expect(
          GamificationAction.values, contains(GamificationAction.friendMade));
      expect(GamificationAction.values,
          contains(GamificationAction.profileCompleted));
      expect(
          GamificationAction.values, contains(GamificationAction.storyPosted));
      expect(GamificationAction.values,
          contains(GamificationAction.arProjectCreated));
      expect(
          GamificationAction.values, contains(GamificationAction.bugReported));
      expect(GamificationAction.values,
          contains(GamificationAction.doubtAnswered));
    });
  });

  group('GamificationActionConfig', () {
    test('constructor sets all fields', () {
      const config = GamificationActionConfig(
        baseXP: 15,
        cooldown: Duration(minutes: 5),
        dbActionType: 'test_action',
      );

      expect(config.baseXP, 15);
      expect(config.cooldown, const Duration(minutes: 5));
      expect(config.dbActionType, 'test_action');
    });
  });

  group('GamificationEvent', () {
    test('constructor sets required fields', () {
      const event = GamificationEvent(
        action: GamificationAction.postCreated,
        userId: 'user-123',
      );

      expect(event.action, GamificationAction.postCreated);
      expect(event.userId, 'user-123');
      expect(event.metadata, isEmpty);
    });

    test('constructor sets metadata when provided', () {
      const event = GamificationEvent(
        action: GamificationAction.quizPassed,
        userId: 'user-456',
        metadata: {'score': 95, 'quiz_id': 'q1'},
      );

      expect(event.metadata['score'], 95);
      expect(event.metadata['quiz_id'], 'q1');
    });

    test('config returns the correct action config', () {
      const event = GamificationEvent(
        action: GamificationAction.postCreated,
        userId: 'user-789',
      );

      final config = event.config;
      expect(config.baseXP, 15);
      expect(config.cooldown, const Duration(minutes: 5));
      expect(config.dbActionType, 'post_created');
    });

    test('cooldownKey combines userId and action name', () {
      const event = GamificationEvent(
        action: GamificationAction.likeGiven,
        userId: 'abc',
      );

      expect(event.cooldownKey, 'abc_likeGiven');
    });
  });

  group('Action configs', () {
    test('all actions have a config', () {
      for (final action in GamificationAction.values) {
        final event = GamificationEvent(
          action: action,
          userId: 'test-user',
        );
        expect(
          () => event.config,
          returnsNormally,
          reason: '${action.name} should have a config entry',
        );
      }
    });

    test('all actions have positive baseXP', () {
      for (final action in GamificationAction.values) {
        final event = GamificationEvent(
          action: action,
          userId: 'test-user',
        );
        expect(event.config.baseXP, greaterThan(0),
            reason: '${action.name} should have positive base XP');
      }
    });

    test('all actions have a non-empty dbActionType', () {
      for (final action in GamificationAction.values) {
        final event = GamificationEvent(
          action: action,
          userId: 'test-user',
        );
        expect(event.config.dbActionType, isNotEmpty,
            reason: '${action.name} should have a dbActionType');
      }
    });

    test('zero-cooldown actions are confirmed', () {
      const zeroCooldownActions = [
        GamificationAction.lessonCompleted,
        GamificationAction.challengeSolved,
        GamificationAction.quizPassed,
        GamificationAction.courseEnrolled,
        GamificationAction.friendMade,
        GamificationAction.arProjectCreated,
      ];

      for (final action in zeroCooldownActions) {
        final event = GamificationEvent(action: action, userId: 'test');
        expect(event.config.cooldown, Duration.zero,
            reason: '${action.name} should have zero cooldown');
      }
    });

    test('cooldown actions have positive durations', () {
      const cooldownActions = [
        GamificationAction.postCreated,
        GamificationAction.commentWritten,
        GamificationAction.likeGiven,
        GamificationAction.messageSent,
        GamificationAction.streakMaintained,
        GamificationAction.talentListed,
        GamificationAction.profileCompleted,
        GamificationAction.storyPosted,
        GamificationAction.bugReported,
        GamificationAction.doubtAnswered,
      ];

      for (final action in cooldownActions) {
        final event = GamificationEvent(action: action, userId: 'test');
        expect(event.config.cooldown, greaterThan(Duration.zero),
            reason: '${action.name} should have a positive cooldown');
      }
    });
  });
}
