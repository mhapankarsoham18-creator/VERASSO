import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/sidequests/quest_service.dart';
import 'package:verasso/features/sidequests/quest_data.dart';

void main() {
  late QuestService questService;

  setUp(() {
    // We instantiate without providing Supabase/ImagePicker
    // because we only test the local offline methods in this file
    // to avoid complex Supabase mocks for now.
    questService = QuestService();
  });

  group('QuestService Daily Quests Generation', () {
    test('Generates exactly 10 quests', () {
      final quests = questService.getDailyQuests('test_user_id_123');
      expect(quests.length, 10);
    });

    test('Quests are deterministic for the same user on the same day', () {
      final quests1 = questService.getDailyQuests('test_user_id_123');
      final quests2 = questService.getDailyQuests('test_user_id_123');
      
      expect(quests1.map((q) => q.id).toList(), equals(quests2.map((q) => q.id).toList()));
    });

    test('Quests are different for different users', () {
      final quests1 = questService.getDailyQuests('user_A');
      final quests2 = questService.getDailyQuests('user_B');
      
      // Highly likely to be different due to large pool
      expect(quests1.map((q) => q.id).toList(), isNot(equals(quests2.map((q) => q.id).toList())));
    });

    test('Quests enforce category limits (max 2 per category)', () {
      final quests = questService.getDailyQuests('user_C');
      
      final Map<QuestCategory, int> counts = {};
      for (var quest in quests) {
        counts[quest.category] = (counts[quest.category] ?? 0) + 1;
      }
      
      for (var count in counts.values) {
        expect(count, lessThanOrEqualTo(2));
      }
    });
  });
}
