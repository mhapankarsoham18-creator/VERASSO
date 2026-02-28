import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';

import 'shimmer_loading.dart';

/// Skeleton loading widget for LeaderboardScreen
/// Skeleton loading widget for the Leaderboard screen.
///
/// Features a special podium layout placeholder followed by a list of rank rows.
class LeaderboardSkeleton extends StatelessWidget {
  /// Creates a [LeaderboardSkeleton].
  const LeaderboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        // Podium skeleton
        SliverToBoxAdapter(child: _buildPodiumSkeleton()),
        // Rank list skeleton
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _RankRowSkeleton(),
              ),
              childCount: 7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumSkeleton() {
    return const ShimmerLoading(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Column(
            children: [
              SkeletonBox(width: 50, height: 50, radius: 25),
              SizedBox(height: 8),
              SkeletonBox(width: 60, height: 12),
              SizedBox(height: 4),
              SkeletonBox(width: 40, height: 10),
              SizedBox(height: 8),
              SkeletonBox(width: 60, height: 70),
            ],
          ),
          SizedBox(width: 16),
          // 1st place (taller)
          Column(
            children: [
              SkeletonBox(width: 60, height: 60, radius: 30),
              SizedBox(height: 8),
              SkeletonBox(width: 70, height: 14),
              SizedBox(height: 4),
              SkeletonBox(width: 50, height: 12),
              SizedBox(height: 8),
              SkeletonBox(width: 60, height: 100),
            ],
          ),
          SizedBox(width: 16),
          // 3rd place
          Column(
            children: [
              SkeletonBox(width: 45, height: 45, radius: 22),
              SizedBox(height: 8),
              SkeletonBox(width: 55, height: 12),
              SizedBox(height: 4),
              SkeletonBox(width: 35, height: 10),
              SizedBox(height: 8),
              SkeletonBox(width: 60, height: 55),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankRowSkeleton extends StatelessWidget {
  const _RankRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      child: GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SkeletonBox(width: 28, height: 28),
            SizedBox(width: 12),
            SkeletonBox(width: 40, height: 40, radius: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 10),
                ],
              ),
            ),
            SkeletonBox(width: 60, height: 20),
          ],
        ),
      ),
    );
  }
}
