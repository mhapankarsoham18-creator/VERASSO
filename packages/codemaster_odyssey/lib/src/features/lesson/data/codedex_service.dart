import 'package:codemaster_odyssey/src/features/lesson/data/lesson_repository.dart';
import 'package:codemaster_odyssey/src/features/lesson/domain/codedex_model.dart';
import 'package:codemaster_odyssey/src/game/engine/combat/combat_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [CodedexService].
final codedexServiceProvider = Provider((ref) {
  return CodedexService(ref.watch(lessonRepositoryProvider));
});

/// Service responsible for managing the Codedex state and unlocking lessons.
class CodedexService {
  final LessonRepository _lessonRepository;

  // Internal state for the Codedex
  Codedex _currentCodedex = Codedex.empty();

  CodedexService(this._lessonRepository) {
    _initializeCodedex();
  }

  /// Returns the current state of the Codedex.
  Codedex get currentCodedex => _currentCodedex;

  /// Unlocks a lesson in the Codedex.
  void unlockLesson(String lessonId) {
    final Map<LanguageArc, List<CodedexEntry>> updatedEntries = {};

    _currentCodedex.entries.forEach((arc, entries) {
      updatedEntries[arc] = entries.map((entry) {
        if (entry.lesson.id == lessonId) {
          return entry.copyWith(isUnlocked: true, unlockedAt: DateTime.now());
        }
        return entry;
      }).toList();
    });

    _currentCodedex = Codedex(entries: updatedEntries);
  }

  List<int> _getRegionsForArc(LanguageArc arc) {
    switch (arc) {
      case LanguageArc.python:
        return [1, 2, 3, 4, 5];
      case LanguageArc.java:
        return [6, 7, 8, 9, 10];
      case LanguageArc.javascript:
        return [11, 12, 13, 14, 15];
      case LanguageArc.cpp:
        return [16, 17, 18, 19, 20];
      case LanguageArc.sql:
        return [21, 22, 23, 24, 25];
    }
  }

  /// Initializes the Codedex by loading all available lessons.
  void _initializeCodedex() {
    final Map<LanguageArc, List<CodedexEntry>> entries = {};

    for (var arc in LanguageArc.values) {
      // Map region ranges to arcs
      final regions = _getRegionsForArc(arc);
      final List<CodedexEntry> arcEntries = [];

      for (var regionId in regions) {
        final lessons = _lessonRepository.getLessonsForRealm(
          regionId.toString(),
        );
        for (var lesson in lessons) {
          arcEntries.add(CodedexEntry(lesson: lesson));
        }
      }
      entries[arc] = arcEntries;
    }

    _currentCodedex = Codedex(entries: entries);
  }
}
