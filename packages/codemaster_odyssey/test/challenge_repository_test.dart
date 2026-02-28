import 'package:codemaster_odyssey/src/features/challenge/data/challenge_repository.dart';
import 'package:codemaster_odyssey/src/features/challenge/domain/challenge_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChallengeRepository returns initial list of challenges', () {
    final container = ProviderContainer();
    final challenges = container.read(challengeRepositoryProvider);

    expect(challenges.length, 3);
    expect(challenges[0].title, 'The Loop of Infinity');
    expect(challenges[0].difficulty, ChallengeDifficulty.easy);
    expect(challenges[0].isCompleted, false);
  });

  test('ChallengeRepository completes a challenge', () {
    final container = ProviderContainer();
    final notifier = container.read(challengeRepositoryProvider.notifier);

    // Initial state
    expect(container.read(challengeRepositoryProvider)[0].isCompleted, false);

    // Complete first challenge
    notifier.completeChallenge('c1');

    // Verify
    expect(container.read(challengeRepositoryProvider)[0].isCompleted, true);
    // Others remain incomplete
    expect(container.read(challengeRepositoryProvider)[1].isCompleted, false);
  });
}
