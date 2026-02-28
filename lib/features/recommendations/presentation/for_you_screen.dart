import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/empty_state_widget.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';

import '../../../core/services/content_recommendation_service.dart';

/// A screen that displays personalized content recommendations for the user.
class ForYouScreen extends ConsumerStatefulWidget {
  /// Creates a [ForYouScreen].
  const ForYouScreen({super.key});

  @override
  ConsumerState<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends ConsumerState<ForYouScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('For You'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const EmptyStateWidget(
                title: 'Authentication Required',
                message:
                    'Please log in to receive personalized recommendations.',
                icon: LucideIcons.lock,
              );
            }

            return FutureBuilder<Map<String, dynamic>>(
              future: Future.wait([
                ref
                    .read(feedRepositoryProvider)
                    .getFeed(userInterests: profile.interests, limit: 10),
                ref
                    .read(contentRecommendationServiceProvider)
                    .recommendSimulations(
                      userId: profile.id,
                      completedSimulations: [],
                      categoryProgress: {},
                      interests: profile.interests,
                      limit: 3,
                    ),
              ]).then((results) => {
                    'posts': results[0] as List<Post>,
                    'sims': results[1] as List<SimulationRecommendation>,
                  }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return AppErrorView(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  );
                }

                final posts = snapshot.data?['posts'] as List<Post>? ?? [];
                final simRecs =
                    snapshot.data?['sims'] as List<SimulationRecommendation>? ??
                        [];

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(feedRepositoryProvider);
                    ref.invalidate(userProfileProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(
                        top: 100, left: 16, right: 16, bottom: 20),
                    children: [
                      _buildSectionHeader('Sims for You', LucideIcons.sparkles),
                      const SizedBox(height: 12),
                      if (simRecs.isEmpty)
                        const EmptyStateWidget(
                          title: 'No Simulation Hints',
                          message:
                              'Complete more simulations for better picks.',
                          icon: LucideIcons.flaskConical,
                        )
                      else
                        ...simRecs.map((rec) => _buildSimulationCard(rec)),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                          'Trending in Network', LucideIcons.trendingUp),
                      const SizedBox(height: 12),
                      if (posts.isEmpty)
                        const EmptyStateWidget(
                          title: 'Interests Mismatch',
                          message: 'No posts found matching your interests.',
                          icon: LucideIcons.searchX,
                        )
                      else
                        ...posts.take(3).map((post) => _buildPostCard(post)),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                          'Connect with Pioneers', LucideIcons.userPlus),
                      const SizedBox(height: 12),
                      const EmptyStateWidget(
                        title: 'Discovery Zone',
                        message: 'New pioneers arriving soon in the network.',
                        icon: LucideIcons.userPlus,
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
      ),
    );
  }

  // Removed unused _buildEmptyState in favor of global EmptyStateWidget

  Widget _buildPostCard(Post post) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: post.authorAvatar != null
              ? NetworkImage(post.authorAvatar!)
              : null,
          child:
              post.authorAvatar == null ? const Icon(LucideIcons.user) : null,
        ),
        title: Text(post.authorName ?? 'Pioneer',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(post.content ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        trailing: const Icon(LucideIcons.chevronRight, size: 16),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSimulationCard(SimulationRecommendation rec) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(LucideIcons.flaskConical, size: 20),
        ),
        title: Text('Simulation: ${rec.simulationId}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(rec.reason,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        trailing: Text('${(rec.score * 100).toInt()}% match',
            style: const TextStyle(fontSize: 10, color: Colors.greenAccent)),
      ),
    );
  }
}
