import 'package:flutter/material.dart';
import 'package:verasso/core/theme/design_system.dart';
import 'package:verasso/core/ui/glass_container.dart';

import 'shimmer_loading.dart';

/// A skeleton loading screen for grid-based views like collections or marketplaces.
///
/// Displays a grid of shimmer boxes mimicking card layouts.
class GridSkeleton extends StatelessWidget {
  /// The number of skeleton items to display.
  final int itemCount;

  /// The number of columns in the grid.
  final int crossAxisCount;

  /// The aspect ratio of each grid item.
  final double childAspectRatio;

  /// Optional padding around the grid.
  final EdgeInsetsGeometry padding;

  /// Creates a [GridSkeleton].
  const GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          child: GlassContainer(
            borderRadius: DesignSystem.borderMedium,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 40, height: 40, radius: 8),
                SizedBox(height: 12),
                SkeletonBox(width: 80, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 50, height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
