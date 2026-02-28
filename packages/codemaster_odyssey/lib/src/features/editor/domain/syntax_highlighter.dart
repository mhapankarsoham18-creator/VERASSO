import 'package:flutter/material.dart';

/// A utility class for providing basic Python syntax highlighting.
class SyntaxHighlighter {
  static const List<String> _keywords = [
    'def',
    'class',
    'if',
    'else',
    'elif',
    'for',
    'while',
    'return',
    'import',
    'from',
    'as',
    'try',
    'except',
    'finally',
    'with',
    'pass',
    'continue',
    'break',
    'True',
    'False',
    'None',
    'print',
  ];

  /// Formats the given [text] into a [TextSpan] with syntax highlighting.
  static TextSpan format(String text) {
    List<TextSpan> spans = [];
    RegExp tokenRegex = RegExp(r'(".*?"|\d+|#.*|\b\w+\b|[(){}\[\],:;])');

    // Simple tokenizer via regex mismatch not perfect but good enough for demo
    // Actually, split by regex keeps delimiters, let's use allMatches

    int lastMatchEnd = 0;
    for (final match in tokenRegex.allMatches(text)) {
      // Add non-matching text (whitespace, operators not in regex)
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: const TextStyle(color: Colors.white),
          ),
        );
      }

      String token = match.group(0)!;
      TextStyle style = const TextStyle(color: Colors.white);

      if (token.startsWith('"') || token.startsWith("'")) {
        // String
        style = const TextStyle(color: Color(0xFFFFD700)); // Gold
      } else if (token.startsWith('#')) {
        // Comment
        style = const TextStyle(color: Colors.grey);
      } else if (RegExp(r'^\d+$').hasMatch(token)) {
        // Number
        style = const TextStyle(color: Color(0xFF00E5FF)); // Cyan
      } else if (_keywords.contains(token)) {
        // Keyword
        style = const TextStyle(
          color: Color(0xFFE040FB),
          fontWeight: FontWeight.bold,
        ); // Neon Purple
      }

      spans.add(TextSpan(text: token, style: style));
      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return TextSpan(
      style: const TextStyle(fontFamily: 'FiraCode'),
      children: spans,
    );
  }
}
