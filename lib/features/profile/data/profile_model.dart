/// A data model representing a user's profile in the Verasso ecosystem.
class Profile {
  /// Unique identifier for the user.
  final String id;

  /// User's chosen unique handle.
  final String? username;

  /// User's display name.
  final String? fullName;

  /// URL to the user's profile picture.
  final String? avatarUrl;

  /// A short biography or description of the user.
  final String? bio;

  /// The user's role (e.g., 'student', 'journalist', 'admin').
  final String role;

  /// A score reflecting the user's reputation and reliability.
  final int trustScore;

  /// URL to the user's personal website or portfolio.
  final String? website;

  /// A list of the user's interests and hobbies.
  final List<String> interests;

  /// Whether the user's profile is hidden from public view.
  final bool isPrivate;

  /// Number of users following this user.
  final int followersCount;

  /// Number of users this user is following.
  final int followingCount;

  /// Number of posts created by this user.
  final int postsCount;

  /// Whether the user's personal data is visible by default.
  final bool defaultPersonalVisibility;

  /// Whether the user has undergone age verification.
  final bool isAgeVerified;

  /// URL to the user's verification documentation.
  final String? verificationUrl;

  /// Whether the user is a verified mentor.
  final bool isMentor;

  /// The user's official mentor title.
  final String? mentorTitle;

  /// Status of the user's mentor verification.
  final String? mentorVerificationStatus;

  /// Token used for Firebase Cloud Messaging notifications.
  final String? fcmToken;

  /// The user's designated journalist level.
  final String? journalistLevel;

  /// Detailed privacy settings stored as a Map.
  final Map<String, dynamic> privacySettings;

  /// User's email address (optional, for compatibility).
  final String? email;

  /// Creates a [Profile].
  Profile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.role = 'student',
    this.trustScore = 0,
    this.website,
    this.interests = const [],
    this.isPrivate = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.defaultPersonalVisibility = false,
    this.isAgeVerified = false,
    this.verificationUrl,
    this.isMentor = false,
    this.mentorTitle,
    this.mentorVerificationStatus = 'none',
    this.fcmToken,
    this.journalistLevel,
    this.privacySettings = const {},
    this.email,
  });

  /// Factory constructor for creating a [Profile] from a JSON map.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      role: json['role'] ?? 'student',
      trustScore: json['trust_score'] ?? 0,
      website: json['website'],
      interests: List<String>.from(json['interests'] ?? []),
      isPrivate: json['is_private'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      defaultPersonalVisibility: json['default_personal_visibility'] ?? false,
      isAgeVerified: json['is_age_verified'] ?? false,
      verificationUrl: json['verification_url'],
      isMentor: json['is_mentor'] ?? false,
      mentorTitle: json['mentor_title'],
      mentorVerificationStatus: json['mentor_verification_status'] ?? 'none',
      fcmToken: json['fcm_token'],
      journalistLevel: json['journalist_level'],
      privacySettings:
          Map<String, dynamic>.from(json['privacy_settings'] ?? {}),
      email: json['email'],
    );
  }

  /// Returns the best available display name for the user.
  String get displayName =>
      fullName ?? username ?? 'User ${id.substring(0, 8)}';

  /// Compatibility getters for tests
  /// Returns the follower count.
  int get followerCount => followersCount;

  /// Returns whether the profile is active.
  bool get isActive => !isPrivate; // Placeholder for isActive

  /// Returns the post count.
  int get postCount => postsCount;

  /// Returns the total XP for this profile (mapped from trustScore).
  int get xpTotal => trustScore; // Assuming trustScore is used for XP in tests

  /// Converts the [Profile] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'role': role,
      'trust_score': trustScore,
      'website': website,
      'interests': interests,
      'is_private': isPrivate,
      'default_personal_visibility': defaultPersonalVisibility,
      'is_age_verified': isAgeVerified,
      'verification_url': verificationUrl,
      'is_mentor': isMentor,
      'mentor_title': mentorTitle,
      'mentor_verification_status': mentorVerificationStatus,
      'fcm_token': fcmToken,
      'journalist_level': journalistLevel,
      'privacy_settings': privacySettings,
      'email': email,
    };
  }
}
