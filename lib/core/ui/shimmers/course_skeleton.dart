import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/shimmers/shimmer_loading.dart';

/// A skeleton loading screen for the course list view.
///
/// Mimics the layout of course cards with shimmer placeholders for thumbnails and text.
class CourseSkeleton extends StatelessWidget {
  /// Creates a [CourseSkeleton].
  const CourseSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: _CourseSkeletonItem(),
        );
      },
    );
  }
}

class _CourseSkeletonItem extends StatelessWidget {
  const _CourseSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Thumbnail
          ShimmerLoading(
            child: SkeletonBox(
              height: 180,
              width: double.infinity,
              radius: 16,
            ),
          ),
          SizedBox(height: 16),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags row
                Row(
                  children: [
                    ShimmerLoading(
                      child: SkeletonBox(width: 60, height: 24, radius: 12),
                    ),
                    SizedBox(width: 8),
                    ShimmerLoading(
                      child: SkeletonBox(width: 80, height: 24, radius: 12),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Title
                ShimmerLoading(
                  child: SkeletonBox(width: double.infinity, height: 24),
                ),
                SizedBox(height: 8),
                ShimmerLoading(
                  child: SkeletonBox(width: 200, height: 24),
                ),
                SizedBox(height: 16),

                // Meta info (author/stats)
                Row(
                  children: [
                    ShimmerLoading(
                      child: SkeletonBox(
                          width: 32, height: 32, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading(
                            child: SkeletonBox(width: 120, height: 16),
                          ),
                          SizedBox(height: 4),
                          ShimmerLoading(
                            child: SkeletonBox(width: 80, height: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
