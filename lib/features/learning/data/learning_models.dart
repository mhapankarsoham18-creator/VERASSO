/// Represents a shared learning resource (e.g., PDF, link, note).
class LearningResource {
  /// Unique identifier of the learning resource.
  final String id;

  /// The ID of the user who uploaded the resource.
  final String userId;

  /// The ID of the study group this resource belongs to (optional).
  final String? groupId;

  /// The title of the resource.
  final String title;

  /// The subject area of the resource.
  final String subject;

  /// Optional description or notes about the resource.
  final String? description;

  /// URL to the actual resource file or link.
  final String? fileUrl;

  /// The average rating given to this resource.
  final double rating;

  /// The date and time when the resource was uploaded.
  final DateTime createdAt;

  /// Creates a [LearningResource] instance.
  LearningResource({
    required this.id,
    required this.userId,
    this.groupId,
    required this.title,
    required this.subject,
    this.description,
    this.fileUrl,
    this.rating = 0,
    required this.createdAt,
  });

  /// Creates a [LearningResource] from a JSON-compatible map.
  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'],
      userId: json['user_id'],
      groupId: json['group_id'],
      title: json['title'],
      subject: json['subject'],
      description: json['description'],
      fileUrl: json['file_url'],
      rating: (json['rating'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [LearningResource] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'title': title,
      'subject': subject,
      'description': description,
      'file_url': fileUrl,
    };
  }
}

/// Represents a collaborative study group.
class StudyGroup {
  /// Unique identifier of the study group.
  final String id;

  /// The name of the study group.
  final String name;

  /// The subject area of focus for the group.
  final String subject;

  /// Optional detailed description of the group's purpose.
  final String? description;

  /// URL to the avatar icon for the group.
  final String? avatarUrl;

  /// The ID of the user who created the group.
  final String creatorId;

  /// The date and time when the group was created.
  final DateTime createdAt;

  /// Creates a [StudyGroup] instance.
  StudyGroup({
    required this.id,
    required this.name,
    required this.subject,
    this.description,
    this.avatarUrl,
    required this.creatorId,
    required this.createdAt,
  });

  /// Creates a [StudyGroup] from a JSON-compatible map.
  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'],
      name: json['name'],
      subject: json['subject'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      creatorId: json['creator_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [StudyGroup] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subject': subject,
      'description': description,
      'avatar_url': avatarUrl,
      'creator_id': creatorId,
    };
  }
}
