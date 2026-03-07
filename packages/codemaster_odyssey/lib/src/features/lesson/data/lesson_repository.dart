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
      ];
    } else if (realmId == '2') {
      // Python Plains - Variables
      return [
        const Lesson(
          id: 'p1_l2',
          title: 'The Mana of Variables',
          description: 'Storing power in named vessels.',
          markdownContent: '''
# Variables: Your Magic Vessels

In Python, you can store data in variables. Think of them as jars that hold different types of mana (data).

```python
mana_level = 100
spell_name = "Fireball"
is_active = True
```

**Task:**
Create a variable named `power` and set it to `50`.
''',
          starterCode: '# Store 50 in a variable named power\n',
          solutionCode: 'power = 50',
        ),
      ];
    } else if (realmId == '3') {
      // Python Plains - Lists
      return [
        const Lesson(
          id: 'p1_l3',
          title: 'The Scroll of Lists',
          description: 'Organizing your collection of fragments.',
          markdownContent: '''
# Lists: Collection of Power

A list allows you to store multiple items in a single variable.

```python
fragments = ["Logic", "Syntax", "Design"]
print(fragments[0]) # Logic
```

**Task:**
Create a list named `inventory` with three strings.
''',
          starterCode: '# Create a list named inventory\n',
          solutionCode: 'inventory = [',
        ),
      ];
    } else if (realmId == '4') {
      // Python Plains - Loops
      return [
        const Lesson(
          id: 'p1_l4',
          title: 'The Eternal Echo',
          description: 'Repeating spells with For Loops.',
          markdownContent: '''
# Loops: Repeating Magic

For loops allow you to run a block of code multiple times.

```python
for i in range(5):
    print("Casting!")
```

**Task:**
Print "Hello" 3 times using a for loop.
''',
          starterCode: '# Write a loop to print "Hello" 3 times\n',
          solutionCode: 'for i in range(3):',
        ),
      ];
    } else if (realmId == '5') {
      // Python Plains - Classes (Boss Region)
      return [
        const Lesson(
          id: 'p1_l5',
          title: 'The Architect\'s Blueprint',
          description: 'Crafting complex magical entities.',
          markdownContent: '''
# Classes: Object Oriented Magic

A class is a blueprint for creating objects. This is how the Lambda Seraph was made!

```python
class Spell:
    def __init__(self, name):
        self.name = name

fire = Spell("Fire")
```

**Task:**
Define a class named `Hero`.
''',
          starterCode: '# Define the Hero class\n',
          solutionCode: 'class Hero',
        ),
      ];
    } else if (realmId == '6') {
      // Java Jungle
      return [
        const Lesson(
          id: 'j6_l1',
          title: 'The Main Method',
          description: 'The ritual of entry.',
          markdownContent: '''
# The Main Portal

In Java, everything must be inside a `class`. The entry point for any spell is the `main` method.

```java
public class Spell {
    public static void main(String[] args) {
        System.out.println("Casting...");
    }
}
```
''',
          starterCode: 'public class Spell {\n  // Define main here\n}',
          solutionCode: 'public static void main(String[] args)',
        ),
      ];
    } else if (realmId == '11') {
      // JavaScript Junction
      return [
        const Lesson(
          id: 'js11_l1',
          title: 'The Magic of Console',
          description: 'Logging to the ether.',
          markdownContent: '''
# Console Log

JavaScript is the language of the browser and the async chaos. We use `console.log()` to debug.

```javascript
console.log("Web Magic!");
```
''',
          starterCode: '// Log something to the console\n',
          solutionCode: 'console.log(',
        ),
      ];
    } else if (realmId == '16') {
      // C++ Citadel
      return [
        const Lesson(
          id: 'cpp16_l1',
          title: 'The Standard Output',
          description: 'Directing the stream.',
          markdownContent: '''
# I/O Streams

In the C++ Citadel, we use `std::cout` to direct our data streams.

```cpp
#include <iostream>
int main() {
    std::cout << "Direct Access!" << std::endl;
    return 0;
}
```
''',
          starterCode: '#include <iostream>\nint main() {\n  \n}',
          solutionCode: 'std::cout <<',
        ),
      ];
    } else if (realmId == '21') {
      // SQL Sea
      return [
        const Lesson(
          id: 'sql21_l1',
          title: 'The Select Query',
          description: 'Extracting knowledge from the depths.',
          markdownContent: '''
# The Select Power

In the SQL Sea, we `SELECT` data from the tables of information.

```sql
SELECT * FROM lessons WHERE region = 'Deep';
```
''',
          starterCode: '-- Select all from users\n',
          solutionCode: 'SELECT * FROM users',
        ),
      ];
    }
    return [];
  }
}
