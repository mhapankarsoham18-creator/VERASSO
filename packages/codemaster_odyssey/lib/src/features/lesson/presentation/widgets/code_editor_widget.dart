import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A simplified code editor widget for lessons.
class CodeEditorWidget extends StatefulWidget {
  /// The initial code content of the editor.
  final String initialCode;

  /// Callback triggered when the code is modified.
  final ValueChanged<String> onChanged;

  /// Creates a [CodeEditorWidget] instance.
  const CodeEditorWidget({
    super.key,
    required this.initialCode,
    required this.onChanged,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          maxLines: null,
          expands: true,
          style: GoogleFonts.firaCode(
            color: const Color(0xFFD4D4D4),
            fontSize: 14,
            height: 1.5,
          ),
          cursorColor: const Color(0xFF00E5FF),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
  }
}
