import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';

import 'shimmer_loading.dart';

/// A skeleton loading screen for the user dashboard.
///
/// Includes placeholders for header text, statistic grids, and recent course items.
class DashboardSkeleton extends StatelessWidget {
  /// Creates a [DashboardSkeleton].
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80), // AppBar space

            // Header Text
            const SkeletonBox(width: 150, height: 24),
            const SizedBox(height: 8),
            const SkeletonBox(width: 220, height: 14),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                  4,
                  (index) => const GlassContainer(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SkeletonBox(width: 30, height: 30, radius: 15),
                              SizedBox(height: 10),
                              SkeletonBox(width: 60, height: 20),
                              SizedBox(height: 5),
                              SkeletonBox(width: 80, height: 12),
                            ],
                          ),
                        ),
                      )),
            ),

            const SizedBox(height: 24),
            const SkeletonBox(width: 200, height: 20), // "Continue Learning"
            const SizedBox(height: 16),

            // Course List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  height: 100,
                  child: Row(
                    children: [
                      SkeletonBox(width: 80, height: 80, radius: 12),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SkeletonBox(width: 150, height: 16),
                            SizedBox(height: 8),
                            SkeletonBox(width: 100, height: 12),
                            SizedBox(height: 12),
                            SkeletonBox(
                                width: double.infinity,
                                height: 6), // Progress bar
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
