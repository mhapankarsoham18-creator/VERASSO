/// Represents a daily learning challenge.
class DailyChallenge {
  /// Unique identifier of the challenge.
  final String id;

  /// The subject category (e.g., 'Math', 'Science').
  final String subject;

  /// The title of the daily challenge.
  final String title;

  /// The content or instructions for the challenge.
  final String content;

  /// The reward points for completing the challenge.
  final int rewardPoints;

  /// The date and time when the challenge was created.
  final DateTime createdAt;

  /// Creates a [DailyChallenge] instance.
  DailyChallenge({
    required this.id,
    required this.subject,
    required this.title,
    required this.content,
    this.rewardPoints = 20,
    required this.createdAt,
  });

  /// Creates a [DailyChallenge] from a JSON-compatible map.
  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'],
      subject: json['subject'],
      title: json['title'],
      content: json['content'],
      rewardPoints: json['reward_points'] ?? 20,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Represents a student's performance score and progress.
class StudentScore {
  /// The ID of the student.
  final String userId;

  /// The number of Karma points earned by the student.
  final int karmaPoints;

  /// Total number of challenges completed.
  final int challengesCompleted;

  /// The date and time of the last completed challenge.
  final DateTime? lastChallengeAt;

  /// Creates a [StudentScore] instance.
  StudentScore({
    required this.userId,
    this.karmaPoints = 0,
    this.challengesCompleted = 0,
    this.lastChallengeAt,
  });

  /// Creates a [StudentScore] from a JSON-compatible map.
  factory StudentScore.fromJson(Map<String, dynamic> json) {
    return StudentScore(
      userId: json['user_id'],
      karmaPoints: json['karma_points'] ?? 0,
      challengesCompleted: json['challenges_completed'] ?? 0,
      lastChallengeAt: json['last_challenge_at'] != null
          ? DateTime.parse(json['last_challenge_at'])
          : null,
    );
  }
}

/// Represents a real-time collaborative study room session.
class StudyRoomSession {
  /// Unique identifier of the session.
  final String id;

  /// The ID of the group this session belongs to.
  final String groupId;

  /// Optional title for the session.
  final String? title;

  /// List of resources pinned to the session.
  final List<dynamic> pinnedResources;

  /// List of user IDs currently active in the session.
  final List<String> activeUsers;

  /// Whether the session is currently live.
  final bool isLive;

  /// The date and time when the session was created.
  final DateTime createdAt;

  /// Creates a [StudyRoomSession] instance.
  StudyRoomSession({
    required this.id,
    required this.groupId,
    this.title,
    this.pinnedResources = const [],
    this.activeUsers = const [],
    this.isLive = true,
    required this.createdAt,
  });

  /// Creates a [StudyRoomSession] from a JSON-compatible map.
  factory StudyRoomSession.fromJson(Map<String, dynamic> json) {
    return StudyRoomSession(
      id: json['id'],
      groupId: json['group_id'],
      title: json['title'],
      pinnedResources: json['pinned_resources'] ?? [],
      activeUsers: List<String>.from(json['active_users'] ?? []),
      isLive: json['is_live'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [StudyRoomSession] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'title': title,
      'pinned_resources': pinnedResources,
      'active_users': activeUsers,
      'is_live': isLive,
    };
  }
}
