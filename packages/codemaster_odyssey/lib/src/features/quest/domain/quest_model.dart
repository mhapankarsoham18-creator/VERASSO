/// Represents a user quest with objectives and rewards.
class Quest {
  /// Unique identifier for the quest.
  final String id;

  /// Human-readable description of the quest objective.
  final String description;

  /// The type of action required to progress the quest.
  final QuestType type;

  /// The required progress value to complete the quest.
  final int targetProgress;

  /// The current progress value achieved by the user.
  final int currentProgress;

  /// Whether the rewards for this quest have been claimed.
  final bool isClaimed;

  /// Experience points rewarded upon completion.
  final int rewardXp;

  /// Creates a [Quest] instance.
  const Quest({
    required this.id,
    required this.description,
    required this.type,
    required this.targetProgress,
    this.currentProgress = 0,
    this.isClaimed = false,
    required this.rewardXp,
  });

  /// Whether the quest objectives have been met.
  bool get isCompleted => currentProgress >= targetProgress;

  /// Creates a copy of this [Quest] with the given fields replaced by new values.
  Quest copyWith({int? currentProgress, bool? isClaimed}) {
    return Quest(
      id: id,
      description: description,
      type: type,
      targetProgress: targetProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      isClaimed: isClaimed ?? this.isClaimed,
      rewardXp: rewardXp,
    );
  }
}

/// Categories of objectives for quests.
enum QuestType {
  /// Completion of an educational lesson.
  lessonCompletion,

  /// Writing a specific number of lines of code.
  codeLines,

  /// Identifying and fixing deliberate bugs.
  bugFixes,
}
