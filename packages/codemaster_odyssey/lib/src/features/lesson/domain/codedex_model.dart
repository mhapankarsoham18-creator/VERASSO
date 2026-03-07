import 'package:codemaster_odyssey/src/features/lesson/domain/lesson_model.dart';
import 'package:codemaster_odyssey/src/game/engine/combat/combat_actions.dart';

/// A collection of [CodedexEntry] items, organized by [LanguageArc].
class Codedex {
  final Map<LanguageArc, List<CodedexEntry>> entries;

  const Codedex({required this.entries});

  /// Factory for creating an empty Codedex.
  factory Codedex.empty() {
    return Codedex(entries: {for (var arc in LanguageArc.values) arc: []});
  }
}

/// Represents an entry in the Codedex.
class CodedexEntry {
  /// The lesson associated with this entry.
  final Lesson lesson;

  /// Whether this lesson has been unlocked/completed.
  final bool isUnlocked;

  /// The timestamp when this entry was unlocked.
  final DateTime? unlockedAt;

  const CodedexEntry({
    required this.lesson,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  CodedexEntry copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return CodedexEntry(
      lesson: lesson,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
