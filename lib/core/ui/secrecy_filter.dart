import 'dart:ui';

import 'package:flutter/material.dart';

/// A widget that obscures its child with a blur or mask.
/// Used to prevent shoulder surfing and hide sensitive data in the app switcher.
/// A security-focused widget that obscures its [child] with a blur or mask.
///
/// Used to prevent shoulder surfing and hide sensitive data (like emails or keys)
/// when the content should be temporarily hidden or in the app switcher.
class SecrecyFilter extends StatelessWidget {
  /// The sensitive content to be optionally obscured.
  final Widget child;

  /// Whether the [child] content is currently visible.
  final bool isContentVisible;

  /// Optional literal text (e.g., "••••@••••.com") to display instead of blurring.
  final String? maskText;

  /// The intensity of the Gaussian blur applied when [isContentVisible] is false.
  final double blurSigma;

  /// Creates a [SecrecyFilter].
  const SecrecyFilter({
    super.key,
    required this.child,
    this.isContentVisible = true,
    this.maskText,
    this.blurSigma = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isContentVisible) {
      return child;
    }

    // If a mask text is provided (like "••••@••••.com"), show that instead
    if (maskText != null) {
      return Text(
        maskText!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
      );
    }

    // Otherwise, apply a Gaussian blur
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
