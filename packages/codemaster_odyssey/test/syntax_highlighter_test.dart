import 'package:codemaster_odyssey/src/features/editor/domain/syntax_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyntaxHighlighter formats python code', () {
    const code = 'def hello():\n  print("World")';
    final span = SyntaxHighlighter.format(code);

    // Verify it returns a text span
    expect(span, isA<TextSpan>());

    // Verify children count (approximate based on tokens)
    // def, space, hello, (), :, \n, space, print, (, "World", )
    expect(span.children, isNotEmpty);

    // Verify keyword highlighting
    final defSpan = span.children!.firstWhere((s) => s.toPlainText() == 'def');
    expect(defSpan.style!.color, const Color(0xFFE040FB));

    // Verify string highlighting
    final stringSpan = span.children!.firstWhere(
      (s) => s.toPlainText() == '"World"',
    );
    expect(stringSpan.style!.color, const Color(0xFFFFD700));
  });
}
