/// Represents a user's entry on a leaderboard.
class LeaderboardEntry {
  /// Unique identifier of the user.
  final String userId;

  /// Display name of the user.
  final String? username;

  /// Optional URL to the user's avatar image.
  final String? avatarUrl;

  /// Total experience points.
  final int? totalXP;

  /// Current level.
  final int? level;

  /// Number of badges earned.
  final int? badges;

  /// The score achieved (Karma or Rating).
  final num? score;

  /// The numerical rank on the leaderboard.
  final int rank;

  /// Creates a [LeaderboardEntry] instance.
  LeaderboardEntry({
    required this.userId,
    this.username,
    this.avatarUrl,
    this.totalXP,
    this.level,
    this.badges,
    this.score,
    required this.rank,
  });

  /// The best available display name for the user.
  String get displayName => username ?? 'User ${userId.substring(0, 6)}';

  /// Creates a [LeaderboardEntry] from a JSON-compatible map.
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'],
      username: json['username'] ?? json['full_name'] ?? 'Anonymous',
      avatarUrl: json['avatar_url'],
      totalXP: json['total_xp'],
      level: json['level'],
      badges: json['badges'] ?? json['badges_earned'],
      score: json['score'] ?? json['overall_score'] ?? json['weekly_score'],
      rank: json['rank'] ?? 0,
    );
  }

  /// Creates a copy with updated rank.
  LeaderboardEntry copyWith({int? rank}) {
    return LeaderboardEntry(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      totalXP: totalXP,
      level: level,
      badges: badges,
      score: score,
      rank: rank ?? this.rank,
    );
  }
}
