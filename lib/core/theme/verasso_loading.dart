import 'package:flutter/material.dart';
import 'colors.dart';

/// A retro, blinking, pixelated loading indicator to replace CircularProgressIndicator.
class VerassoLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const VerassoLoading({super.key, this.size = 24.0, this.color});

  @override
  State<VerassoLoading> createState() => _VerassoLoadingState();
}

class _VerassoLoadingState extends State<VerassoLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Step function for sharp pixelated blinking
        final bool isVisible = _controller.value > 0.5;
        return Opacity(
          opacity: isVisible ? 1.0 : 0.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color ?? context.colors.primary,
              border: Border.all(color: context.colors.textPrimary, width: 2),
            ),
          ),
        );
      },
    );
  }
}
