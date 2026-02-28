import 'package:flutter/material.dart';
import 'package:verasso/core/theme/design_system.dart';
import 'package:verasso/core/ui/glass_container.dart';

import 'shimmer_loading.dart';

/// A generic list skeleton that can be customized for various list-based views.
class ListSkeleton extends StatelessWidget {
  /// The number of skeleton items to display.
  final int itemCount;

  /// Whether to show a circular avatar placeholder in each row.
  final bool showAvatar;

  /// The height of each skeleton item row.
  final double height;

  /// Optional padding around the list.
  final EdgeInsetsGeometry padding;

  /// Creates a [ListSkeleton].
  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.showAvatar = true,
    this.height = 70,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ShimmerLoading(
            child: GlassContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: DesignSystem.borderMedium,
              child: Row(
                children: [
                  if (showAvatar) ...[
                    const SkeletonBox(width: 40, height: 40, radius: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                            width: 150 + (index % 3 * 30).toDouble(),
                            height: 14),
                        const SizedBox(height: 8),
                        const SkeletonBox(width: 100, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
