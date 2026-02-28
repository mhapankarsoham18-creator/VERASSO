import 'package:codemaster_odyssey/src/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:codemaster_odyssey/src/features/ai_tutor/domain/tutor_hint_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = AiTutorRepository();

  test('AiTutor detects missing colon', () {
    final hints = repository.analyzeCode('def foo()');
    expect(hints, isNotEmpty);
    expect(hints.first.severity, HintSeverity.error);
    expect(hints.first.message, contains('missing a colon'));
  });

  test('AiTutor detects assignment in if', () {
    final hints = repository.analyzeCode('if x = 5:');
    expect(hints, isNotEmpty);
    expect(hints.first.message, contains('use `==`'));
  });

  test('AiTutor detects print without parentheses', () {
    final hints = repository.analyzeCode('print "Hello"');
    expect(hints, isNotEmpty);
    expect(hints.first.message, contains('requires parentheses'));
  });

  test('AiTutor gives praise for clean code', () {
    final hints = repository.analyzeCode('if x == 5:\n  print("Hello")');
    expect(hints, isNotEmpty);
    expect(hints.first.severity, HintSeverity.info);
    expect(hints.first.message, contains('clean'));
  });
}
