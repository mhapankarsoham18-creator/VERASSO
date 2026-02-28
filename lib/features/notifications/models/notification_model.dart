/// Model representing a notification in the system.
class NotificationModel {
  /// Unique identifier for the notification.
  final String id;

  /// Unique identifier for the user who received the notification.
  final String userId;

  /// The type of notification (e.g., like, comment, system).
  final NotificationType type;

  /// The headline of the notification.
  final String title;

  /// The detailed message content.
  final String body;

  /// Optional metadata associated with the notification.
  final Map<String, dynamic>? data;

  /// The date and time when the notification was read, if any.
  final DateTime? readAt;

  /// The date and time when the notification was created.
  final DateTime createdAt;

  /// Creates a [NotificationModel].
  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  /// Creates a [NotificationModel] from a JSON map.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: _parseType(json['type']),
      title: json['title'],
      body: json['body'],
      data: json['data'] != null ? json['data'] as Map<String, dynamic> : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Whether the notification has been read.
  bool get isRead => readAt != null;

  /// Converts the [NotificationModel] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'read_at': readAt?.toIso8601String(),
    };
  }

  static NotificationType _parseType(String typeStr) {
    try {
      return NotificationType.values.firstWhere((e) => e.name == typeStr);
    } catch (_) {
      return NotificationType.system;
    }
  }
}

/// The various types of notifications supported by the system.
enum NotificationType {
  /// Notification for a post like.
  like,

  /// Notification for a comment on a post.
  comment,

  /// Notification for a new follower.
  follow,

  /// Notification for a user mention.
  mention,

  /// Notification for a direct message.
  message,

  /// Notification for a story like.
  storyLike,

  /// Notification for a story comment.
  storyComment,

  /// Notification for earning an achievement.
  achievement,

  /// Notification for leveling up.
  levelUp,

  /// Notification for leaderboard updates.
  leaderboard,

  /// Generic system notification.
  system,

  /// Generic social interaction notification.
  socialInteraction,

  /// Notification related to job postings or applications.
  job,
}
