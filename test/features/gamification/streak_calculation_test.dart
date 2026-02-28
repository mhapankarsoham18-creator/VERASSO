import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/gamification/gamification_engine.dart';

void main() {
  group('BadgeSystem', () {
    group('badge definitions', () {
      test('contains all expected badges', () {
        expect(BadgeSystem.badges.containsKey('novice_coder'), isTrue);
        expect(BadgeSystem.badges.containsKey('python_padawan'), isTrue);
        expect(BadgeSystem.badges.containsKey('function_master'), isTrue);
        expect(BadgeSystem.badges.containsKey('challenge_champion'), isTrue);
        expect(BadgeSystem.badges.containsKey('codemaster'), isTrue);
      });

      test('all badges have positive XP rewards', () {
        for (final badge in BadgeSystem.badges.values) {
          expect(badge.xpReward, greaterThan(0),
              reason: '${badge.id} should have positive XP reward');
        }
      });

      test('all badges have non-empty titles', () {
        for (final badge in BadgeSystem.badges.values) {
          expect(badge.title, isNotEmpty,
              reason: '${badge.id} should have a title');
        }
      });

      test('all badges have non-empty descriptions', () {
        for (final badge in BadgeSystem.badges.values) {
          expect(badge.description, isNotEmpty,
              reason: '${badge.id} should have a description');
        }
      });

      test('all badges have icon paths', () {
        for (final badge in BadgeSystem.badges.values) {
          expect(badge.icon, isNotEmpty,
              reason: '${badge.id} should have an icon');
        }
      });
    });

    group('badge requirements', () {
      test('novice_coder unlocks at 1+ lesson completed', () {
        final badge = BadgeSystem.badges['novice_coder']!;
        expect(badge.requirement({'lessons_completed': 0}), isFalse);
        expect(badge.requirement({'lessons_completed': 1}), isTrue);
        expect(badge.requirement({'lessons_completed': 10}), isTrue);
      });

      test('novice_coder handles missing key gracefully', () {
        final badge = BadgeSystem.badges['novice_coder']!;
        expect(badge.requirement(<String, dynamic>{}), isFalse);
      });

      test('python_padawan requires module 1 completed', () {
        final badge = BadgeSystem.badges['python_padawan']!;
        expect(badge.requirement({'modules_completed': []}), isFalse);
        expect(
            badge.requirement({
              'modules_completed': [1]
            }),
            isTrue);
        expect(
            badge.requirement({
              'modules_completed': [2, 3]
            }),
            isFalse);
      });

      test('function_master requires module 2 completed', () {
        final badge = BadgeSystem.badges['function_master']!;
        expect(
            badge.requirement({
              'modules_completed': [1]
            }),
            isFalse);
        expect(
            badge.requirement({
              'modules_completed': [2]
            }),
            isTrue);
        expect(
            badge.requirement({
              'modules_completed': [1, 2]
            }),
            isTrue);
      });

      test('challenge_champion requires 30+ challenges solved', () {
        final badge = BadgeSystem.badges['challenge_champion']!;
        expect(badge.requirement({'challenges_solved': 29}), isFalse);
        expect(badge.requirement({'challenges_solved': 30}), isTrue);
        expect(badge.requirement({'challenges_solved': 100}), isTrue);
      });

      test('codemaster requires all modules, challenges, and quizzes', () {
        final badge = BadgeSystem.badges['codemaster']!;

        // Not enough modules
        expect(
            badge.requirement({
              'modules_completed': [1, 2, 3],
              'challenges_solved': 61,
              'quizzes_completed': 8,
            }),
            isFalse);

        // Not enough challenges
        expect(
            badge.requirement({
              'modules_completed': [1, 2, 3, 4, 5, 6, 7, 8],
              'challenges_solved': 60,
              'quizzes_completed': 8,
            }),
            isFalse);

        // Not enough quizzes
        expect(
            badge.requirement({
              'modules_completed': [1, 2, 3, 4, 5, 6, 7, 8],
              'challenges_solved': 61,
              'quizzes_completed': 7,
            }),
            isFalse);

        // All requirements met
        expect(
            badge.requirement({
              'modules_completed': [1, 2, 3, 4, 5, 6, 7, 8],
              'challenges_solved': 61,
              'quizzes_completed': 8,
            }),
            isTrue);
      });
    });
  });

  group('BadgeDefinition', () {
    test('constructor creates with all required fields', () {
      const badge = BadgeDefinition(
        id: 'test_badge',
        title: 'Test Badge',
        description: 'A test badge',
        icon: 'assets/badges/test.png',
        requirement: _alwaysTrue,
        xpReward: 50,
      );

      expect(badge.id, 'test_badge');
      expect(badge.title, 'Test Badge');
      expect(badge.description, 'A test badge');
      expect(badge.icon, 'assets/badges/test.png');
      expect(badge.xpReward, 50);
    });
  });
}

bool _alwaysTrue(dynamic _) => true;
