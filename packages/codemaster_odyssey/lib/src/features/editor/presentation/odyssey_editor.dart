import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../editor/domain/debugger_model.dart';
import '../../editor/domain/syntax_highlighter.dart';

/// Custom controller for the [OdysseyEditor] that applies syntax highlighting.
class CodeController extends TextEditingController {
  /// Creates a [CodeController] with optional initial [text].
  CodeController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(style: style, children: [SyntaxHighlighter.format(text)]);
  }
}

/// A specialized code editor for the Odyssey with syntax highlighting and debugger integration.
class OdysseyEditor extends StatefulWidget {
  /// The initial code content of the editor.
  final String initialCode;

  /// Callback triggered when the code is modified.
  final ValueChanged<String> onChanged;

  /// The line number currently marked as active in the debugger.
  final int? activeLine;

  /// The list of variables to display in the sidebar.
  final List<VariableState>? variables;

  /// Creates an [OdysseyEditor] widget.
  const OdysseyEditor({
    super.key,
    required this.initialCode,
    required this.onChanged,
    this.activeLine,
    this.variables,
  });

  @override
  State<OdysseyEditor> createState() => _OdysseyEditorState();
}

class _OdysseyEditorState extends State<OdysseyEditor> {
  late final CodeController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.95),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gutter (Line Numbers)
          Container(
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final lineCount = _controller.text.split('\n').length;
                    return Column(
                      children: List.generate(lineCount, (index) {
                        final isCurrent = widget.activeLine == index + 1;
                        return Container(
                          height: 21,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.firaCode(
                                color: isCurrent
                                    ? const Color(0xFF00E5FF)
                                    : Colors.grey.withValues(alpha: 0.5),
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),

          // Editor Field
          Expanded(
            child: Stack(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.firaCode(fontSize: 14, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    isDense: true,
                  ),
                  cursorColor: const Color(0xFF00E5FF),
                ),
                // Line Highlight overlay in Editor
                if (widget.activeLine != null)
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        margin: EdgeInsets.only(
                          top: (widget.activeLine! - 1) * 21.0,
                        ),
                        height: 21,
                        width: double.infinity,
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Variable Sidebar (The "Scroll of Truth")
          if (widget.variables != null && widget.variables!.isNotEmpty)
            Container(
              width: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                border: Border(
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VARIABLES',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.variables!.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.name,
                            style: GoogleFonts.firaCode(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            v.value,
                            style: GoogleFonts.firaCode(
                              color: const Color(0xFF00E5FF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideX(
              begin: 1.0,
              duration: 400.ms,
              curve: Curves.easeOut,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = CodeController(text: widget.initialCode);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }
}
