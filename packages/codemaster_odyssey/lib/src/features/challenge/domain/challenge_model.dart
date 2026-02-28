/// Represents a coding challenge with requirements and rewards.
class Challenge {
  /// Unique identifier for the challenge.
  final String id;

  /// Human-readable title of the challenge.
  final String title;

  /// Detailed description of the problem to solve.
  final String description;

  /// Difficulty level of the challenge.
  final ChallengeDifficulty difficulty;

  /// Boilerplate code provided to start the challenge.
  final String starterCode;

  /// The expected output to validate the user's solution.
  final String expectedOutput;

  /// Experience points rewarded upon successful completion.
  final int xpReward;

  /// Whether the user has already completed this challenge.
  final bool isCompleted;

  /// Creates a [Challenge] instance.
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.starterCode,
    required this.expectedOutput,
    required this.xpReward,
    this.isCompleted = false,
  });

  /// Creates a copy of this [Challenge] with the given fields replaced.
  Challenge copyWith({bool? isCompleted}) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      difficulty: difficulty,
      starterCode: starterCode,
      expectedOutput: expectedOutput,
      xpReward: xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Difficulty levels for coding challenges.
enum ChallengeDifficulty {
  /// Beginner level, focuses on basic syntax.
  easy,

  /// Intermediate level, involves simple logic.
  medium,

  /// Advanced level, requires complex algorithms.
  hard,

  /// Master level, extremely difficult puzzles.
  legendary,
}
