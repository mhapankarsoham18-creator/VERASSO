import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/discovery/domain/weighted_tag_scorer.dart';

void main() {
  group('WeightedTagScorer', () {
    group('score - tag matching', () {
      test('returns 0 for no matching tags and no popularity', () {
        final result = WeightedTagScorer.score(
          itemTags: ['flutter', 'dart'],
          userInterests: ['python', 'rust'],
        );
        expect(result, 0.0);
      });

      test('returns matchWeight for exact tag match', () {
        final result = WeightedTagScorer.score(
          itemTags: ['flutter'],
          userInterests: ['flutter'],
        );
        expect(result, WeightedTagScorer.matchWeight);
      });

      test('accumulates matchWeight for multiple exact matches', () {
        final result = WeightedTagScorer.score(
          itemTags: ['flutter', 'dart'],
          userInterests: ['flutter', 'dart'],
        );
        expect(result, WeightedTagScorer.matchWeight * 2);
      });

      test('is case-insensitive for item tags', () {
        final result = WeightedTagScorer.score(
          itemTags: ['Flutter'],
          userInterests: ['flutter'],
        );
        expect(result, WeightedTagScorer.matchWeight);
      });

      test('trims whitespace from item tags', () {
        final result = WeightedTagScorer.score(
          itemTags: ['  flutter  '],
          userInterests: ['flutter'],
        );
        expect(result, WeightedTagScorer.matchWeight);
      });

      test(
          'returns secondaryMatchWeight for partial match (tag contains interest)',
          () {
        final result = WeightedTagScorer.score(
          itemTags: ['flutter dev'],
          userInterests: ['flutter'],
        );
        // 'flutter dev' contains 'flutter' → partial match
        expect(result, WeightedTagScorer.secondaryMatchWeight);
      });

      test(
          'returns secondaryMatchWeight for partial match (interest contains tag)',
          () {
        final result = WeightedTagScorer.score(
          itemTags: ['ai'],
          userInterests: ['ai research'],
        );
        // 'ai research' contains 'ai' → partial match
        expect(result, WeightedTagScorer.secondaryMatchWeight);
      });

      test('returns 0 when both lists are empty', () {
        final result = WeightedTagScorer.score(
          itemTags: [],
          userInterests: [],
        );
        expect(result, 0.0);
      });

      test('returns 0 when item tags is empty', () {
        final result = WeightedTagScorer.score(
          itemTags: [],
          userInterests: ['flutter', 'dart'],
        );
        expect(result, 0.0);
      });
    });

    group('score - popularity boost', () {
      test('adds popularity boost proportional to popularityScore', () {
        final result = WeightedTagScorer.score(
          itemTags: [],
          userInterests: [],
          popularityScore: 100,
        );
        expect(result, 100 * WeightedTagScorer.popularityWeight);
      });

      test('combines tag match with popularity boost', () {
        final result = WeightedTagScorer.score(
          itemTags: ['flutter'],
          userInterests: ['flutter'],
          popularityScore: 20,
        );
        expect(
          result,
          WeightedTagScorer.matchWeight +
              (20 * WeightedTagScorer.popularityWeight),
        );
      });

      test('zero popularity adds nothing', () {
        final result = WeightedTagScorer.score(
          itemTags: ['flutter'],
          userInterests: ['flutter'],
          popularityScore: 0,
        );
        expect(result, WeightedTagScorer.matchWeight);
      });
    });

    group('score - recency decay', () {
      test('applies recency decay based on age in days', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

        final result = WeightedTagScorer.score(
          itemTags: ['flutter'],
          userInterests: ['flutter'],
          popularityScore: 0,
          createdAt: threeDaysAgo,
        );

        // matchWeight (5.0) - 3 days * 0.5 = 5.0 - 1.5 = 3.5
        expect(result, closeTo(3.5, 0.1));
      });

      test('score does not go below zero with old content', () {
        final veryOld = DateTime.now().subtract(const Duration(days: 365));

        final result = WeightedTagScorer.score(
          itemTags: ['flutter'],
          userInterests: ['flutter'],
          createdAt: veryOld,
        );

        expect(result, 0.0);
      });

      test('no decay when createdAt is null', () {
        final result = WeightedTagScorer.score(
          itemTags: ['flutter'],
          userInterests: ['flutter'],
        );
        expect(result, WeightedTagScorer.matchWeight);
      });

      test('minimal decay for very recent content', () {
        final justNow = DateTime.now();

        final result = WeightedTagScorer.score(
          itemTags: ['flutter'],
          userInterests: ['flutter'],
          createdAt: justNow,
        );

        // 0 days old → no decay
        expect(result, WeightedTagScorer.matchWeight);
      });
    });

    group('score - combined scenarios', () {
      test('full scoring with multiple matches, popularity, and recency', () {
        final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

        final result = WeightedTagScorer.score(
          itemTags: ['flutter', 'dart', 'mobile dev'],
          userInterests: ['flutter', 'dart', 'web'],
          popularityScore: 50,
          createdAt: oneDayAgo,
        );

        // 2 exact matches × 5.0 = 10.0
        // 0 partial matches = 0
        // popularity = 50 × 0.1 = 5.0
        // recency = 1 * 0.5 = 0.5 decay
        // Total = 10.0 + 5.0 - 0.5 = 14.5
        expect(result, closeTo(14.5, 0.1));
      });

      test('static constants have expected values', () {
        expect(WeightedTagScorer.matchWeight, 5.0);
        expect(WeightedTagScorer.secondaryMatchWeight, 2.0);
        expect(WeightedTagScorer.popularityWeight, 0.1);
      });
    });
  });
}
