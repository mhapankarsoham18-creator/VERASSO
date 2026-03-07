/// Python Arc code challenge data for Regions 1-5.
class PythonChallenges {
  /// Returns challenge data for the given region.
  static Map<String, dynamic> getChallenge(int region) {
    return _challenges[region.clamp(1, 5) - 1];
  }

  static const List<Map<String, dynamic>> _challenges = [
    // Region 1: Basic Syntax
    {
      'question': 'Which line has a syntax error?\n\n'
          '1: x = 10\n'
          '2: if x > 5\n'
          '3:     print("big")\n',
      'options': [
        'Line 1: x = 10',
        'Line 2: if x > 5  (missing colon)',
        'Line 3: print("big")',
        'No error',
      ],
      'correct_answer': 'Line 2: if x > 5  (missing colon)',
    },
    // Region 2: Variables & Types
    {
      'question': 'What is the output?\n\n'
          'x = "3"\n'
          'y = 2\n'
          'print(x * y)\n',
      'options': [
        '6',
        '"33"',
        'TypeError',
        '5',
      ],
      'correct_answer': '"33"',
    },
    // Region 3: Loops
    {
      'question': 'How many times does this loop run?\n\n'
          'for i in range(3):\n'
          '    for j in range(2):\n'
          '        print(i, j)\n',
      'options': [
        '3 times',
        '5 times',
        '6 times',
        '2 times',
      ],
      'correct_answer': '6 times',
    },
    // Region 4: Recursion
    {
      'question': 'What does this return?\n\n'
          'def f(n):\n'
          '    if n <= 1: return n\n'
          '    return f(n-1) + f(n-2)\n\n'
          'f(5)\n',
      'options': [
        '5',
        '8',
        '3',
        '13',
      ],
      'correct_answer': '5',
    },
    // Region 5: Classes & OOP
    {
      'question': 'What prints?\n\n'
          'class Dog:\n'
          '    def __init__(self, name):\n'
          '        self.name = name\n'
          '    def speak(self):\n'
          '        return f"{self.name} says Woof!"\n\n'
          'print(Dog("Rex").speak())\n',
      'options': [
        'Dog says Woof!',
        'Rex says Woof!',
        'Error: missing self',
        'None',
      ],
      'correct_answer': 'Rex says Woof!',
    },
  ];
}
