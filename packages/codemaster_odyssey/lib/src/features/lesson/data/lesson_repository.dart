import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lesson/domain/lesson_model.dart';

/// Provider for the [LessonRepository] instance.
final lessonRepositoryProvider = Provider((ref) => LessonRepository());

/// Repository responsible for providing lesson content for different realms.
class LessonRepository {
  /// Returns a list of [Lesson]s for a given [realmId].
  List<Lesson> getLessonsForRealm(String realmId) {
    if (realmId == '1') {
      // Python Plains
      return [
        const Lesson(
          id: 'p1_l1',
          title: 'The Print Spell',
          description: 'Learn how to speak to the world.',
          markdownContent: '''
# The Power of Print

In the Python Plains, the most basic spell is `print()`. It allows you to shout words into the void!

```python
print("Hello, Verasso!")
```

**Task:**
Use the print function to say "I am a Coder".
''',
          starterCode: '''# Write your code below
print("Hello, World!")
''',
          solutionCode: 'print("I am a Coder")',
        ),
        // Add more lessons here
      ];
    }
    return [];
  }
}
