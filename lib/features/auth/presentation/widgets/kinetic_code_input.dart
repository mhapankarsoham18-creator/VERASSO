import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../settings/presentation/theme_controller.dart';

/// A specialized input widget for entering multi-digit authentication codes.
///
/// Features animated slots, haptic feedback, and a shake animation on error.
class KineticCodeInput extends ConsumerStatefulWidget {
  /// The controller for the code being entered.
  final TextEditingController controller;

  /// The expected length of the code (e.g., 6 or 8 characters).
  final int codeLength;

  /// Callback triggered when the code reaches [codeLength].
  final VoidCallback onCompleted;

  /// Whether to display an error state (triggers shake animation).
  final bool hasError;

  /// Creates a [KineticCodeInput].
  const KineticCodeInput({
    super.key,
    required this.controller,
    required this.codeLength,
    required this.onCompleted,
    this.hasError = false,
  });

  @override
  ConsumerState<KineticCodeInput> createState() => _KineticCodeInputState();
}

class _KineticCodeInputState extends ConsumerState<KineticCodeInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final isPowerSave = ref.watch(themeControllerProvider).isPowerSaveMode;
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            // Hidden TextField to capture input
            Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: true,
                maxLength: widget.codeLength,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  if (value.length == widget.codeLength) {
                    widget.onCompleted();
                  }
                  setState(() {});
                },
                decoration: const InputDecoration(counterText: ""),
              ),
            ),
            // Custom Code Slots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.codeLength, (index) {
                final char = widget.controller.text.length > index
                    ? widget.controller.text[index]
                    : "";
                final isActive = widget.controller.text.length == index;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 50,
                    child: GlassContainer(
                      opacity: isActive ? 0.2 : 0.1,
                      child: Center(
                        child: Text(
                          char,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(target: widget.hasError ? 1 : 0)
                      .shake(
                          offset: const Offset(4, 0), hz: 10, duration: 300.ms)
                      .animate(
                        onPlay: (controller) => (isActive && !isPowerSave)
                            ? controller.repeat(reverse: true)
                            : null,
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 600.ms,
                        curve: Curves.easeInOut,
                      )
                      .animate()
                      .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                      .slideY(begin: 0.2, end: 0, delay: (index * 50).ms),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
