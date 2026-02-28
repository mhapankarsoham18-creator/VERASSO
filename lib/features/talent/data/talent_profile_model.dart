/// Represents an education entry in a talent profile.
class EducationEntry {
  /// The name of the school or institution.
  final String school;

  /// The degree or certification obtained.
  final String degree;

  /// The start date of the education.
  final String? startDate;

  /// The end date of the education.
  final String? endDate;

  /// Creates an [EducationEntry] instance.
  EducationEntry({
    required this.school,
    required this.degree,
    this.startDate,
    this.endDate,
  });

  /// Creates an [EducationEntry] from a JSON map.
  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    return EducationEntry(
      school: json['school'] ?? '',
      degree: json['degree'] ?? '',
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }

  /// Creates a copy of [EducationEntry] with updated fields.
  EducationEntry copyWith({
    String? school,
    String? degree,
    String? startDate,
    String? endDate,
  }) {
    return EducationEntry(
      school: school ?? this.school,
      degree: degree ?? this.degree,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Converts the [EducationEntry] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'school': school,
      'degree': degree,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

/// Represents an experience entry in a talent profile.
class ExperienceEntry {
  /// The name of the company.
  final String company;

  /// The job title.
  final String title;

  /// The start date of the experience.
  final String? startDate;

  /// The end date of the experience.
  final String? endDate;

  /// The description of the role.
  final String? description;

  /// Creates an [ExperienceEntry] instance.
  ExperienceEntry({
    required this.company,
    required this.title,
    this.startDate,
    this.endDate,
    this.description,
  });

  /// Creates an [ExperienceEntry] from a JSON map.
  factory ExperienceEntry.fromJson(Map<String, dynamic> json) {
    return ExperienceEntry(
      company: json['company'] ?? '',
      title: json['title'] ?? '',
      startDate: json['startDate'],
      endDate: json['endDate'],
      description: json['description'],
    );
  }

  /// Creates a copy of [ExperienceEntry] with updated fields.
  ExperienceEntry copyWith({
    String? company,
    String? title,
    String? startDate,
    String? endDate,
    String? description,
  }) {
    return ExperienceEntry(
      company: company ?? this.company,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
    );
  }

  /// Converts the [ExperienceEntry] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
  }
}

/// Represents a comprehensive talent profile.
class TalentProfile {
  /// The unique identifier for the profile.
  final String id;

  /// The professional headline.
  final String? headline;

  /// The biography.
  final String? bio;

  /// List of skills.
  final List<String> skills;

  /// List of work experiences.
  final List<ExperienceEntry> experience;

  /// List of education entries.
  final List<EducationEntry> education;

  /// List of portfolio URLs.
  final List<String> portfolioUrls;

  /// The date and time when the profile was created.
  final DateTime? createdAt;

  /// The date and time when the profile was last updated.
  final DateTime? updatedAt;

  // Joined from main profile
  /// The username of the talent (joined field).
  final String? username;

  /// The full name of the talent (joined field).
  final String? fullName;

  /// The avatar URL of the talent (joined field).
  final String? avatarUrl;

  /// Creates a [TalentProfile] instance.
  TalentProfile({
    required this.id,
    this.headline,
    this.bio,
    this.skills = const [],
    this.experience = const [],
    this.education = const [],
    this.portfolioUrls = const [],
    this.createdAt,
    this.updatedAt,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  /// Creates a [TalentProfile] from a JSON map.
  factory TalentProfile.fromJson(Map<String, dynamic> json) {
    return TalentProfile(
      id: json['id'],
      headline: json['headline'],
      bio: json['bio'],
      skills: List<String>.from(json['skills'] ?? []),
      experience: (json['experience'] as List? ?? [])
          .map((e) => ExperienceEntry.fromJson(e))
          .toList(),
      education: (json['education'] as List? ?? [])
          .map((e) => EducationEntry.fromJson(e))
          .toList(),
      portfolioUrls: List<String>.from(json['portfolio_urls'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      username: json['profiles']?['username'],
      fullName: json['profiles']?['full_name'],
      avatarUrl: json['profiles']?['avatar_url'],
    );
  }

  /// Creates a copy of [TalentProfile] with updated fields.
  TalentProfile copyWith({
    String? id,
    String? headline,
    String? bio,
    List<String>? skills,
    List<ExperienceEntry>? experience,
    List<EducationEntry>? education,
    List<String>? portfolioUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? fullName,
    String? avatarUrl,
  }) {
    return TalentProfile(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Converts the [TalentProfile] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headline': headline,
      'bio': bio,
      'skills': skills,
      'experience': experience.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'portfolio_urls': portfolioUrls,
    };
  }
}
