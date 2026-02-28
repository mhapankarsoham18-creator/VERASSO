import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../features/settings/presentation/theme_controller.dart';

/// A utility widget that applies a shimmering effect to its [child] when [isLoading] is true.
///
/// Adapts its colors based on the current theme brightness (dark/light).
class ShimmerLoading extends ConsumerWidget {
  /// The content to apply the shimmer effect to.
  final Widget child;

  /// Whether the shimmering effect should be active.
  final bool isLoading;

  /// Creates a [ShimmerLoading].
  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isLoading) {
      return child;
    }

    final themeState = ref.watch(themeControllerProvider);
    if (themeState.isPowerSaveMode) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey[300]!,
      highlightColor: isDark ? Colors.white24 : Colors.grey[100]!,
      child: child,
    );
  }
}

/// A basic shape used as a placeholder within a [ShimmerLoading] effect.
class SkeletonBox extends StatelessWidget {
  /// The width of the skeleton box.
  final double width;

  /// The height of the skeleton box.
  final double height;

  /// The border radius for the rectangle (defaults to 8).
  final double radius;

  /// The geometric shape of the skeleton box (defaults to [BoxShape.rectangle]).
  final BoxShape shape;

  /// Creates a [SkeletonBox].
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black, // Color doesn't matter, it's masked by Shimmer
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        shape: shape,
      ),
    );
  }
}
