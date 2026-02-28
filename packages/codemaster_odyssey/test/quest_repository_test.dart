import 'package:codemaster_odyssey/src/features/quest/data/quest_repository.dart';
import 'package:codemaster_odyssey/src/features/quest/domain/quest_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QuestRepository increments progress correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state: Quest 1 (Complete 1 Lesson) should be 0/1
    var quests = container.read(questRepositoryProvider);
    var lessonQuest = quests.firstWhere(
      (q) => q.type == QuestType.lessonCompletion,
    );
    expect(lessonQuest.currentProgress, 0);
    expect(lessonQuest.isCompleted, false);

    // Increment progress
    container
        .read(questRepositoryProvider.notifier)
        .incrementProgress(QuestType.lessonCompletion);

    // Verify progress updated
    quests = container.read(questRepositoryProvider);
    lessonQuest = quests.firstWhere(
      (q) => q.type == QuestType.lessonCompletion,
    );
    expect(lessonQuest.currentProgress, 1);
    expect(lessonQuest.isCompleted, true);
    expect(lessonQuest.isClaimed, false);

    // Claim quest
    container.read(questRepositoryProvider.notifier).claimQuest(lessonQuest.id);

    // Verify claimed
    quests = container.read(questRepositoryProvider);
    lessonQuest = quests.firstWhere(
      (q) => q.type == QuestType.lessonCompletion,
    );
    expect(lessonQuest.isClaimed, true);
  });
}
