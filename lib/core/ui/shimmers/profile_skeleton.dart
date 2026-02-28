import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/shimmers/shimmer_loading.dart';

/// A skeleton loading screen for the user profile page.
///
/// Includes placeholders for the profile header, statistics, and bio section.
class ProfileSkeleton extends StatelessWidget {
  /// Creates a [ProfileSkeleton].
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
      children: [
        // Header Card
        const GlassContainer(
          child: Column(
            children: [
              ShimmerLoading(
                child: SkeletonBox(
                    width: 100, height: 100, shape: BoxShape.circle),
              ),
              SizedBox(height: 16),
              ShimmerLoading(
                child: SkeletonBox(width: 150, height: 28),
              ),
              SizedBox(height: 8),
              ShimmerLoading(
                child: SkeletonBox(width: 100, height: 16),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatSkeleton(),
                  _StatSkeleton(),
                  _StatSkeleton(),
                  _StatSkeleton(),
                ],
              ),
              SizedBox(height: 16),
              ShimmerLoading(
                child: SkeletonBox(width: 80, height: 32, radius: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bio & Details
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerLoading(
                child: SkeletonBox(width: 60, height: 20),
              ),
              const SizedBox(height: 12),
              const ShimmerLoading(
                child: SkeletonBox(width: double.infinity, height: 14),
              ),
              const SizedBox(height: 8),
              const ShimmerLoading(
                child: SkeletonBox(width: 200, height: 14),
              ),
              const SizedBox(height: 16),
              const ShimmerLoading(
                child: SkeletonBox(width: 80, height: 20),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(
                    3,
                    (index) => const ShimmerLoading(
                          child: SkeletonBox(width: 70, height: 32, radius: 16),
                        )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerLoading(
          child: SkeletonBox(width: 40, height: 24),
        ),
        SizedBox(height: 4),
        ShimmerLoading(
          child: SkeletonBox(width: 60, height: 14),
        ),
      ],
    );
  }
}
