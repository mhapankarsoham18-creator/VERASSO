import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';

/// Provider for the [ContentRecommendationService].
final contentRecommendationServiceProvider = Provider((ref) {
  return ContentRecommendationService(
    ref.watch(courseRepositoryProvider),
    client: SupabaseService.client,
  );
});

/// Content recommendation algorithm for Verasso
/// Suggests personalized simulations (courses), posts, and users based on user behavior
class ContentRecommendationService {
  final CourseRepository _courseRepository;
  final SupabaseClient _client;

  /// Creates a [ContentRecommendationService].
  ContentRecommendationService(this._courseRepository, {SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Fetches recommended posts using collaborative filtering RPC
  Future<List<PostRecommendation>> fetchRecommendedPosts({
    int limit = 10,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client.rpc(
        'get_recommended_posts',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      final posts =
          (response as List).map((json) => Post.fromJson(json)).toList();

      return posts
          .map((p) => PostRecommendation(
                postId: p.id,
                score: 0.9, // Default RPC score
                reason: 'Users with similar interests liked this',
              ))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch recommended posts', error: e);
      return [];
    }
  }

  /// Fetches suggested users to follow using Friend-of-Friend RPC
  Future<List<UserRecommendation>> fetchRecommendedUsers({
    int limit = 5,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client.rpc(
        'get_recommended_users',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      return (response as List)
          .map((json) => UserRecommendation(
                userId: json['id'],
                score: 0.7,
                reason: 'Followed by people you follow',
              ))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch recommended users', error: e);
      return [];
    }
  }

  /// Fetches user interests from the new user_interests table
  Future<List<Map<String, dynamic>>> fetchUserInterests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('user_interests')
          .select('category, score, weight')
          .eq('user_id', userId)
          .order('score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Failed to fetch user interests', error: e);
      return [];
    }
  }

  /// Collaborative filtering for post recommendations (Static/Offline version)
  List<PostRecommendation> recommendPosts({
    required String userId,
    required List<String> likedPosts,
    required List<String> followedUsers,
    required Map<String, List<String>> userPostLikes, // userId -> postIds
    int limit = 10,
  }) {
    final recommendations = <PostRecommendation>[];

    // Algorithm 1: Collaborative Filtering
    final similarUsers = _findSimilarUsers(userId, likedPosts, userPostLikes);

    for (final similarUser in similarUsers.take(5)) {
      final theirLikes = userPostLikes[similarUser.userId] ?? [];
      for (final postId in theirLikes) {
        if (!likedPosts.contains(postId)) {
          recommendations.add(PostRecommendation(
            postId: postId,
            score: similarUser.similarity * 0.8,
            reason: 'Users with similar interests liked this',
          ));
        }
      }
    }

    // Algorithm 2: Following-Based
    for (final followedId in followedUsers) {
      final posts = userPostLikes[followedId] ?? [];
      for (final postId in posts) {
        recommendations.add(PostRecommendation(
          postId: postId,
          score: 0.9,
          reason: 'From someone you follow',
        ));
      }
    }

    return _rankPosts(recommendations).take(limit).toList();
  }

  /// Generate personalized course/simulation recommendations
  Future<List<SimulationRecommendation>> recommendSimulations({
    required String userId,
    required List<String> completedSimulations,
    required Map<String, int> categoryProgress, // category -> count
    required List<String> interests,
    int limit = 5,
  }) async {
    final recommendations = <SimulationRecommendation>[];

    // Fetch real published courses
    final allCourses = await _courseRepository.getPublishedCourses();

    // Fetch weighted interests from database if available
    final dbInterests = await fetchUserInterests();
    final Map<String, double> interestMap = {};
    for (final i in dbInterests) {
      interestMap[i['category']] =
          (i['score'] as int) * (i['weight'] as double);
    }

    // 1. Matching by Interests (Database Weighted)
    if (interestMap.isNotEmpty) {
      for (final entry in interestMap.entries) {
        final matching = allCourses.where((c) =>
            (c.title.toLowerCase().contains(entry.key.toLowerCase()) ||
                (c.description
                        ?.toLowerCase()
                        .contains(entry.key.toLowerCase()) ??
                    false)) &&
            !completedSimulations.contains(c.id));

        recommendations.addAll(matching.map((c) => SimulationRecommendation(
              simulationId: c.id,
              score: 0.95,
              reason: 'Selected for you based on your interest in ${entry.key}',
            )));
      }
    } else {
      // Fallback to legacy interests list
      for (final interest in interests) {
        final matching = allCourses.where((c) =>
            (c.title.toLowerCase().contains(interest.toLowerCase()) ||
                (c.description
                        ?.toLowerCase()
                        .contains(interest.toLowerCase()) ??
                    false)) &&
            !completedSimulations.contains(c.id));

        recommendations.addAll(matching.map((c) => SimulationRecommendation(
              simulationId: c.id,
              score: 0.9,
              reason: 'Matches your interest: $interest',
            )));
      }
    }

    // 2. Matching by Category Progress
    if (categoryProgress.isNotEmpty) {
      final topCategory = categoryProgress.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final categoryMatches = allCourses.where((c) =>
          c.title.toLowerCase().contains(topCategory.toLowerCase()) &&
          !completedSimulations.contains(c.id));

      recommendations
          .addAll(categoryMatches.map((c) => SimulationRecommendation(
                simulationId: c.id,
                score: 0.85,
                reason: 'Similar to your progress in $topCategory',
              )));
    }

    // 3. General "Hot" recommendations
    if (recommendations.length < limit) {
      final remaining = allCourses
          .where((c) =>
              !completedSimulations.contains(c.id) &&
              !recommendations.any((r) => r.simulationId == c.id))
          .take(limit - recommendations.length);

      recommendations.addAll(remaining.map((c) => SimulationRecommendation(
            simulationId: c.id,
            score: 0.7,
            reason: 'Trending in the community',
          )));
    }

    return _scoreAndRank(recommendations).take(limit).toList();
  }

  /// Suggest users to follow (Legacy/Offline version)
  List<UserRecommendation> recommendUsers({
    required String userId,
    required List<String> followedUsers,
    required Map<String, List<String>> userFollows, // userId -> followedIds
    required Map<String, List<String>> userInterests, // userId -> interests
    required List<String> myInterests,
    int limit = 5,
  }) {
    final recommendations = <UserRecommendation>[];

    for (final followedId in followedUsers) {
      final theirFollows = userFollows[followedId] ?? [];
      for (final potentialFollow in theirFollows) {
        if (potentialFollow != userId &&
            !followedUsers.contains(potentialFollow)) {
          recommendations.add(UserRecommendation(
            userId: potentialFollow,
            score: 0.7,
            reason: 'Followed by people you follow',
          ));
        }
      }
    }

    for (final entry in userInterests.entries) {
      if (entry.key == userId || followedUsers.contains(entry.key)) continue;

      final overlap = _calculateInterestOverlap(myInterests, entry.value);
      if (overlap > 0.3) {
        recommendations.add(UserRecommendation(
          userId: entry.key,
          score: overlap,
          reason: 'Similar interests',
        ));
      }
    }

    return _rankUsers(recommendations).take(limit).toList();
  }

  double _calculateInterestOverlap(
      List<String> myInterests, List<String> theirInterests) {
    final overlap = myInterests.where((i) => theirInterests.contains(i)).length;
    return myInterests.isEmpty ? 0.0 : overlap / myInterests.length;
  }

  double _calculateJaccardSimilarity(List<String> setA, List<String> setB) {
    final intersection = setA.where((item) => setB.contains(item)).length;
    final union = {...setA, ...setB}.length;
    return union > 0 ? intersection / union : 0.0;
  }

  List<SimilarUser> _findSimilarUsers(
    String userId,
    List<String> myLikes,
    Map<String, List<String>> allUserLikes,
  ) {
    final similarities = <SimilarUser>[];

    for (final entry in allUserLikes.entries) {
      if (entry.key == userId) continue;

      final theirLikes = entry.value;
      final similarity = _calculateJaccardSimilarity(myLikes, theirLikes);

      if (similarity > 0.2) {
        similarities
            .add(SimilarUser(userId: entry.key, similarity: similarity));
      }
    }

    similarities.sort((a, b) => b.similarity.compareTo(a.similarity));
    return similarities;
  }

  List<PostRecommendation> _rankPosts(List<PostRecommendation> recs) {
    final Map<String, PostRecommendation> uniquePosts = {};
    for (final rec in recs) {
      if (!uniquePosts.containsKey(rec.postId) ||
          uniquePosts[rec.postId]!.score < rec.score) {
        uniquePosts[rec.postId] = rec;
      }
    }

    final sorted = uniquePosts.values.toList();
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  List<UserRecommendation> _rankUsers(List<UserRecommendation> recs) {
    final Map<String, UserRecommendation> uniqueUsers = {};
    for (final rec in recs) {
      if (!uniqueUsers.containsKey(rec.userId) ||
          uniqueUsers[rec.userId]!.score < rec.score) {
        uniqueUsers[rec.userId] = rec;
      }
    }

    final sorted = uniqueUsers.values.toList();
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  List<SimulationRecommendation> _scoreAndRank(
      List<SimulationRecommendation> recs) {
    final Map<String, SimulationRecommendation> uniqueRecs = {};
    for (final rec in recs) {
      if (!uniqueRecs.containsKey(rec.simulationId) ||
          uniqueRecs[rec.simulationId]!.score < rec.score) {
        uniqueRecs[rec.simulationId] = rec;
      }
    }

    final sorted = uniqueRecs.values.toList();
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }
}

/// Stores recommendation metadata for a feed post.
class PostRecommendation {
  /// The ID of the recommended post.
  final String postId;

  /// The calculated score for this recommendation.
  final double score;

  /// The reason why this post was recommended.
  final String reason;

  /// Creates a [PostRecommendation].
  PostRecommendation({
    required this.postId,
    required this.score,
    required this.reason,
  });
}

/// Represents a user with a calculated similarity score.
class SimilarUser {
  /// The ID of the similar user.
  final String userId;

  /// The similarity score (e.g. 0.0 to 1.0).
  final double similarity;

  /// Creates a [SimilarUser] entry.
  SimilarUser({required this.userId, required this.similarity});
}

/// Stores recommendation metadata for a simulation.
class SimulationRecommendation {
  /// The ID of the recommended simulation.
  final String simulationId;

  /// The calculated score for this recommendation.
  final double score;

  /// The reason why this simulation was recommended.
  final String reason;

  /// Creates a [SimulationRecommendation].
  SimulationRecommendation({
    required this.simulationId,
    required this.score,
    required this.reason,
  });
}

/// Stores recommendation metadata for a user to follow.
class UserRecommendation {
  /// The ID of the recommended user.
  final String userId;

  /// The calculated score for this recommendation.
  final double score;

  /// The reason why this user was recommended.
  final String reason;

  /// Creates a [UserRecommendation].
  UserRecommendation({
    required this.userId,
    required this.score,
    required this.reason,
  });
}
