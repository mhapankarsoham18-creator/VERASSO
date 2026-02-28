import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../challenge/domain/challenge_model.dart';

/// Provider for the [ChallengeRepository] instance.
final challengeRepositoryProvider =
    NotifierProvider<ChallengeRepository, List<Challenge>>(
      ChallengeRepository.new,
    );

/// Repository responsible for managing coding challenges and their completion state.
class ChallengeRepository extends Notifier<List<Challenge>> {
  @override
  List<Challenge> build() {
    return [
      const Challenge(
        id: 'c1',
        title: 'The Loop of Infinity',
        description: 'Create a loop that prints "Echo" 3 times.',
        difficulty: ChallengeDifficulty.easy,
        starterCode: '# Print "Echo" 3 times\nfor i in range( ):\n  print("")',
        expectedOutput: 'Echo\nEcho\nEcho',
        xpReward: 100,
      ),
      const Challenge(
        id: 'c2',
        title: 'The Conditional Gate',
        description: 'Write a function that checks if a number is even.',
        difficulty: ChallengeDifficulty.medium,
        starterCode:
            'def is_even(num):\n  # Your code here\n  pass\n\nprint(is_even(4))\nprint(is_even(7))',
        expectedOutput: 'True\nFalse',
        xpReward: 250,
      ),
      const Challenge(
        id: 'c3',
        title: 'Sorter of Spells',
        description: 'Sort a list of spell power levels [5, 2, 9, 1].',
        difficulty: ChallengeDifficulty.hard,
        starterCode: 'spells = [5, 2, 9, 1]\n# Sort the list\nprint(spells)',
        expectedOutput: '[1, 2, 5, 9]',
        xpReward: 500,
      ),
    ];
  }

  /// Marks a challenge as completed by its [id].
  void completeChallenge(String id) {
    state = [
      for (final challenge in state)
        if (challenge.id == id)
          challenge.copyWith(isCompleted: true)
        else
          challenge,
    ];
  }
}
