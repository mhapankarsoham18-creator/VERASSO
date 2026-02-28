import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quest/domain/quest_model.dart';

/// Provider for the [QuestRepository] instance.
final questRepositoryProvider = NotifierProvider<QuestRepository, List<Quest>>(
  QuestRepository.new,
);

/// Repository responsible for managing daily quests and user progress.
class QuestRepository extends Notifier<List<Quest>> {
  @override
  List<Quest> build() {
    // Mock: Generate daily quests
    return [
      const Quest(
        id: 'q1',
        description: 'Complete 1 Lesson',
        type: QuestType.lessonCompletion,
        targetProgress: 1,
        rewardXp: 50,
      ),
      const Quest(
        id: 'q2',
        description: 'Fix 3 Errors',
        type: QuestType.bugFixes,
        targetProgress: 3,
        rewardXp: 30,
      ),
    ];
  }

  /// Claims the rewards for a completed quest by its [questId].
  void claimQuest(String questId) {
    state = [
      for (final quest in state)
        if (quest.id == questId && quest.isCompleted)
          quest.copyWith(isClaimed: true)
        else
          quest,
    ];
    // In a real app, this would also add XP to the Avatar
  }

  /// Increments the progress of all active quests of a specific [type].
  void incrementProgress(QuestType type, {int amount = 1}) {
    state = [
      for (final quest in state)
        if (quest.type == type && !quest.isCompleted && !quest.isClaimed)
          quest.copyWith(currentProgress: quest.currentProgress + amount)
        else
          quest,
    ];
  }
}
