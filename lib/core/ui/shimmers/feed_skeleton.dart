import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';

import 'shimmer_loading.dart';

/// A skeleton loading screen for the social feed or activity stream.
///
/// Mimics a list of posts with placeholders for avatars, content lines, and images.
class FeedSkeleton extends StatelessWidget {
  /// Creates a [FeedSkeleton].
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 100, bottom: 80, left: 16, right: 16),
      itemCount: 4, // Show 4 skeleton items
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: _PostSkeletonItem(),
        );
      },
    );
  }
}

class _PostSkeletonItem extends StatelessWidget {
  const _PostSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      child: GlassContainer(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                SkeletonBox(width: 40, height: 40, radius: 20), // Avatar
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 10),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            // Content Lines
            SkeletonBox(width: double.infinity, height: 12),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 12),
            SizedBox(height: 8),
            SkeletonBox(width: 200, height: 12),
            SizedBox(height: 16),
            // Image Placeholder
            SkeletonBox(width: double.infinity, height: 180, radius: 12),
            SizedBox(height: 12),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 60, height: 20),
                SkeletonBox(width: 60, height: 20),
                SkeletonBox(width: 24, height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
