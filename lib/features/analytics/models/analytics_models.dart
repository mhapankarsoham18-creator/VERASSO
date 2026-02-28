/// Represents performance statistics for a specific piece of content.
class ContentStats {
  /// Unique identifier of the content.
  final String contentId;

  /// Type of the content (e.g., 'post', 'story').
  final String contentType;

  /// Total number of views this content has received.
  final int viewsCount;

  /// Total number of likes this content has received.
  final int likesCount;

  /// Total number of comments this content has received.
  final int commentsCount;

  /// Total number of shares this content has performed.
  final int sharesCount;

  /// The ratio of interactions to views for this content.
  final double engagementRate;

  /// Creates a [ContentStats] instance.
  ContentStats({
    required this.contentId,
    required this.contentType,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.engagementRate,
  });

  /// Creates a [ContentStats] from a JSON-compatible map.
  factory ContentStats.fromJson(Map<String, dynamic> json) {
    return ContentStats(
      contentId: json['content_id'],
      contentType: json['content_type'],
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      engagementRate: (json['engagement_rate'] ?? 0).toDouble(),
    );
  }

  /// Calculates the total number of interactions (likes + comments + shares).
  int get totalEngagement => likesCount + commentsCount + sharesCount;
}

/// Represents engagement metrics for a specific date.
class EngagementData {
  /// The date for which these engagement metrics were recorded.
  final DateTime date;

  /// Number of posts created on this date.
  final int posts;

  /// Number of likes received on this date.
  final int likes;

  /// Number of comments received on this date.
  final int comments;

  /// Creates an [EngagementData] instance.
  EngagementData({
    required this.date,
    required this.posts,
    required this.likes,
    required this.comments,
  });

  /// Creates an [EngagementData] from a JSON-compatible map.
  factory EngagementData.fromJson(Map<String, dynamic> json) {
    return EngagementData(
      date: DateTime.parse(json['date']),
      posts: json['posts'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
    );
  }

  /// Calculates the total number of interactions for the day.
  int get totalEngagement => posts + likes + comments;
}

/// Represents high-level statistics for a user, aggregated from various activities.
class UserStats {
  /// Unique identifier of the user these stats belong to.
  final String userId;

  /// Total number of posts created by the user.
  final int postsCount;

  /// Total number of users following this user.
  final int followersCount;

  /// Total number of users this user is following.
  final int followingCount;

  /// Total number of likes received across all content.
  final int likesReceived;

  /// Total number of comments received across all content.
  final int commentsReceived;

  /// A calculated score representing the user's overall engagement level.
  final double engagementScore;

  /// The timestamp of the user's last recorded activity.
  final DateTime? lastActive;

  /// The timestamp when these statistics were last recalculated.
  final DateTime updatedAt;

  /// Creates a [UserStats] instance.
  UserStats({
    required this.userId,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.likesReceived,
    required this.commentsReceived,
    required this.engagementScore,
    this.lastActive,
    required this.updatedAt,
  });

  /// Creates a [UserStats] instance from a JSON-compatible map.
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'],
      postsCount: json['posts_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      likesReceived: json['likes_received'] ?? 0,
      commentsReceived: json['comments_received'] ?? 0,
      engagementScore: (json['engagement_score'] ?? 0).toDouble(),
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : null,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
