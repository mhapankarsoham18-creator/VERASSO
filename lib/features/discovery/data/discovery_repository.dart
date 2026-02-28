import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/profile_controller.dart';
import '../../social/data/feed_repository.dart';
import '../../social/data/post_model.dart';
import '../domain/weighted_tag_scorer.dart';

/// Provider for the [DiscoveryRepository] instance.
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref);
});

/// Repository for managing content discovery and personalization logic.
class DiscoveryRepository {
  final Ref _ref;

  /// Creates a [DiscoveryRepository] with a [Ref].
  DiscoveryRepository(this._ref);

  /// Fetches a personalized discovery feed mixing posts and other content
  Future<List<Post>> getDiscoveryFeed() async {
    final userProfile = _ref.read(userProfileProvider).value;
    final userInterests = userProfile?.interests ?? [];

    // 1. Fetch Candidates (e.g., global feed for now, or specific discovery query)
    // In a real app, we'd use an Edge Function for this.
    // Here we fetch recent posts and re-rank them client-side.
    final feedRepo = _ref.read(feedRepositoryProvider);
    // Assuming we have a method to get raw feed or using existing getFeed
    final rawPosts = await feedRepo.getFeed();

    // 2. Score and Sort
    final scoredPosts = rawPosts.map((post) {
      final score = WeightedTagScorer.score(
        itemTags: post.tags,
        userInterests: userInterests,
        popularityScore: post.likesCount + (post.commentsCount * 2),
        createdAt: post.createdAt,
      );
      return MapEntry(post, score);
    }).toList();

    // Sort by score descending
    scoredPosts.sort((a, b) => b.value.compareTo(a.value));

    // Return the post objects
    return scoredPosts.map((e) => e.key).toList();
  }
}
