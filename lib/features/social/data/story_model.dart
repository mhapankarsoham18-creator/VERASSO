/// Represents a transient user story that expires after 24 hours.
class Story {
  /// Unique identifier of the story.
  final String id;

  /// ID of the user who authored the story.
  final String userId;

  /// URL of the story media (image/video).
  final String mediaUrl;

  /// Type of media ('image' or 'video').
  final String mediaType;

  /// When the story was created.
  final DateTime createdAt;

  /// When the story expires.
  final DateTime expiresAt;

  /// Author's display name.
  final String? authorName;

  /// Author's profile image URL.
  final String? authorAvatar;

  /// Creates a [Story] instance.
  Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    this.authorName,
    this.authorAvatar,
  });

  /// Creates a [Story] instance from a JSON map.
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['user_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'] ?? 'image',
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      authorName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      authorAvatar: json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }
}
