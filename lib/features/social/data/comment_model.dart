import 'post_model.dart';

/// Represents a user comment on a [Post].
class Comment {
  /// Unique identifier of the comment.
  final String id;

  /// ID of the post this comment belongs to.
  final String postId;

  /// ID of the user who authored the comment.
  final String userId;

  /// Textual content of the comment.
  final String content;

  /// When the comment was posted.
  final DateTime createdAt;

  /// Author's display name (populated via join).
  final String? authorName;

  /// Author's profile image URL (populated via join).
  final String? authorAvatar;

  /// ID of the parent comment if this is a reply.
  final String? parentCommentId;

  /// Creates a [Comment] instance.
  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.parentCommentId,
  });

  /// Creates a [Comment] instance from a JSON map.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      authorName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      authorAvatar: json['profiles'] != null ? json['profiles']['avatar_url'] : null,
      parentCommentId: json['parent_comment_id'],
    );
  }

  /// Converts the [Comment] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
    };
  }
}
