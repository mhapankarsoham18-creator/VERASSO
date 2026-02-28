/// Represents a mentor's profile.
class MentorProfile {
  /// The unique identifier for the profile.
  final String id;

  /// The ID of the user associated with this profile.
  final String userId;

  /// The mentor's headline.
  final String? headline;

  /// List of degrees or certifications.
  final List<dynamic> degrees;

  /// Years of experience.
  final int experienceYears;

  /// List of specializations.
  final List<String> specializations;

  /// The mentor's biography.
  final String? bio;

  /// The verification status (e.g., 'pending', 'verified').
  final String verificationStatus;

  /// List of verification document URLs.
  final List<String> verificationDocs;

  /// The average rating of the mentor.
  final double averageRating;

  /// The total number of mentees.
  final int totalMentees;

  /// The date and time when the profile was created.
  final DateTime createdAt;

  /// Creates a [MentorProfile] instance.
  MentorProfile({
    required this.id,
    required this.userId,
    this.headline,
    this.degrees = const [],
    this.experienceYears = 0,
    this.specializations = const [],
    this.bio,
    this.verificationStatus = 'pending',
    this.verificationDocs = const [],
    this.averageRating = 0.0,
    this.totalMentees = 0,
    required this.createdAt,
  });

  /// Creates a [MentorProfile] from a JSON map.
  factory MentorProfile.fromJson(Map<String, dynamic> json) {
    return MentorProfile(
      id: json['id'],
      userId: json['user_id'],
      headline: json['headline'],
      degrees: json['degrees'] ?? [],
      experienceYears: json['experience_years'] ?? 0,
      specializations: List<String>.from(json['specializations'] ?? []),
      bio: json['bio'],
      verificationStatus: json['verification_status'] ?? 'pending',
      verificationDocs: List<String>.from(json['verification_docs'] ?? []),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalMentees: json['total_mentees'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [MentorProfile] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'headline': headline,
      'degrees': degrees,
      'experience_years': experienceYears,
      'specializations': specializations,
      'bio': bio,
      'verification_status': verificationStatus,
      'verification_docs': verificationDocs,
    };
  }
}
