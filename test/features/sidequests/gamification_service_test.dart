import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/sidequests/title_system.dart';

void main() {
  group('TitleSystem', () {
    group('getCurrentTier', () {
      test('returns Wanderer at 0 XP', () {
        final tier = TitleSystem.getCurrentTier(0);
        expect(tier.title, 'Wanderer');
        expect(tier.emoji, '🚶‍♂️');
      });

      test('returns Explorer at 500 XP', () {
        final tier = TitleSystem.getCurrentTier(500);
        expect(tier.title, 'Explorer');
      });

      test('returns Explorer at 999 XP (just below Adventurer)', () {
        final tier = TitleSystem.getCurrentTier(999);
        expect(tier.title, 'Explorer');
      });

      test('returns Adventurer at 1500 XP', () {
        final tier = TitleSystem.getCurrentTier(1500);
        expect(tier.title, 'Adventurer');
      });

      test('returns Legend at 20000 XP', () {
        final tier = TitleSystem.getCurrentTier(20000);
        expect(tier.title, 'Legend');
        expect(tier.emoji, '👑');
      });

      test('returns Legend at very high XP', () {
        final tier = TitleSystem.getCurrentTier(999999);
        expect(tier.title, 'Legend');
      });
    });

    group('getNextTier', () {
      test('returns Explorer as next tier for 0 XP', () {
        final nextTier = TitleSystem.getNextTier(0);
        expect(nextTier, isNotNull);
        expect(nextTier!.title, 'Explorer');
      });

      test('returns Adventurer as next tier for 500 XP', () {
        final nextTier = TitleSystem.getNextTier(500);
        expect(nextTier, isNotNull);
        expect(nextTier!.title, 'Adventurer');
      });

      test('returns null when already at max tier', () {
        final nextTier = TitleSystem.getNextTier(20000);
        expect(nextTier, isNull);
      });

      test('returns null when above max tier', () {
        final nextTier = TitleSystem.getNextTier(50000);
        expect(nextTier, isNull);
      });
    });

    group('getProgressToNextTier', () {
      test('returns 0.0 at the start of a tier', () {
        final progress = TitleSystem.getProgressToNextTier(0);
        expect(progress, 0.0);
      });

      test('returns 0.5 halfway through Wanderer tier', () {
        // Wanderer is 0-499, Explorer starts at 500
        final progress = TitleSystem.getProgressToNextTier(250);
        expect(progress, closeTo(0.5, 0.01));
      });

      test('returns 1.0 when at max tier', () {
        final progress = TitleSystem.getProgressToNextTier(20000);
        expect(progress, 1.0);
      });
    });

    group('didJustLevelUp', () {
      test('returns true when crossing a tier boundary', () {
        expect(TitleSystem.didJustLevelUp(499, 500), true); // Wanderer -> Explorer
      });

      test('returns false when staying within same tier', () {
        expect(TitleSystem.didJustLevelUp(100, 200), false); // Still Wanderer
      });

      test('returns true when jumping multiple tiers', () {
        expect(TitleSystem.didJustLevelUp(400, 1600), true); // Wanderer -> Adventurer
      });

      test('returns false when XP does not change tier', () {
        expect(TitleSystem.didJustLevelUp(500, 600), false); // Still Explorer
      });
    });
  });
}
