/// Represents a user's submission for a community challenge.
class ChallengeSubmission {
  /// Unique identifier of the submission.
  final String id;

  /// The ID of the challenge this submission is for.
  final String challengeId;

  /// The ID of the user who submitted.
  final String userId;

  /// Optional URL to the submitted content (e.g., image, link).
  final String? contentUrl;

  /// Current status of the submission ('Pending', 'Approved', 'Rejected').
  final String status;

  /// Feedback provided by the reviewer.
  final String? feedback;

  /// The date and time when the submission was made.
  final DateTime submittedAt;

  // Joined Submitter
  /// The display name of the submitter (optional, populated via joins).
  final String? userName;

  /// The avatar URL of the submitter (optional, populated via joins).
  final String? userAvatar;

  /// Creates a [ChallengeSubmission] instance.
  ChallengeSubmission({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.contentUrl,
    required this.status,
    this.feedback,
    required this.submittedAt,
    this.userName,
    this.userAvatar,
  });

  /// Creates a [ChallengeSubmission] from a JSON-compatible map.
  factory ChallengeSubmission.fromJson(Map<String, dynamic> json) {
    return ChallengeSubmission(
      id: json['id'],
      challengeId: json['challenge_id'],
      userId: json['user_id'],
      contentUrl: json['content_url'],
      status: json['status'],
      feedback: json['feedback'],
      submittedAt: DateTime.parse(json['submitted_at']),
      userName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      userAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }

  /// Returns `true` if the submission status is 'Approved'.
  bool get isApproved => status == 'Approved';

  /// Returns `true` if the submission status is 'Pending'.
  bool get isPending => status == 'Pending';
}

/// Represents a community-driven learning challenge.
class CommunityChallenge {
  /// Unique identifier of the challenge.
  final String id;

  /// The ID of the user who created the challenge.
  final String creatorId;

  /// The title of the challenge.
  final String title;

  /// Detailed description of the challenge tasks.
  final String description;

  /// The subject category (e.g., 'Physics', 'Chemistry').
  final String category;

  /// The difficulty level (e.g., 'Beginner', 'Advanced').
  final String difficulty;

  /// The amount of Karma points rewarded for completion.
  final int karmaReward;

  /// Optional expiration date for the challenge.
  final DateTime? expiresAt;

  /// The date when the challenge was created.
  final DateTime createdAt;

  // Joined Creator
  /// The display name of the creator (optional, populated via joins).
  final String? creatorName;

  /// The avatar URL of the creator (optional, populated via joins).
  final String? creatorAvatar;

  /// Creates a [CommunityChallenge] instance.
  CommunityChallenge({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.karmaReward,
    this.expiresAt,
    required this.createdAt,
    this.creatorName,
    this.creatorAvatar,
  });

  /// Creates a [CommunityChallenge] from a JSON-compatible map.
  factory CommunityChallenge.fromJson(Map<String, dynamic> json) {
    return CommunityChallenge(
      id: json['id'],
      creatorId: json['creator_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      karmaReward: json['karma_reward'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      creatorName:
          json['profiles'] != null ? json['profiles']['full_name'] : null,
      creatorAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }
}
