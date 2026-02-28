/// Represents a collection of stories grouped as a highlight.
class HighlightModel {
  /// Unique identifier of the highlight.
  final String id;

  /// Unique identifier of the user who created the highlight.
  final String userId;

  /// Title of the highlight.
  final String title;

  /// URL of the cover image for the highlight.
  final String? coverUrl;

  /// List of story IDs included in this highlight.
  final List<String> storyIds;

  /// The timestamp when the highlight was created.
  final DateTime createdAt;

  /// Creates a [HighlightModel].
  HighlightModel({
    required this.id,
    required this.userId,
    required this.title,
    this.coverUrl,
    required this.storyIds,
    required this.createdAt,
  });

  /// Creates a [HighlightModel] from a JSON map.
  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      coverUrl: json['cover_url'],
      storyIds: List<String>.from(json['story_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [HighlightModel] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'cover_url': coverUrl,
      'story_ids': storyIds,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
