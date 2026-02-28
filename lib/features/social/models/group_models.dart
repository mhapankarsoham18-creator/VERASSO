/// Represents a collaborative study or interest group (Circle).
class Group {
  /// Unique identifier of the group.
  final String id;

  /// Name of the group.
  final String name;

  /// Brief description of the group's purpose.
  final String? description;

  /// URL of the group's profile image.
  final String? avatarUrl;

  /// ID of the user who owns the group.
  final String ownerId;

  /// Whether access to the group is restricted.
  final bool isPrivate;

  /// Current number of members in the group.
  final int memberCount;

  /// When the group was created.
  final DateTime createdAt;

  /// Creates a [Group] instance.
  Group({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.isPrivate,
    required this.memberCount,
    required this.createdAt,
  });

  /// Creates a [Group] from a JSON map.
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      ownerId: json['owner_id'],
      isPrivate: json['is_private'] ?? false,
      memberCount: json['member_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Represents a member's association with a group.
class GroupMember {
  /// ID of the group.
  final String groupId;

  /// ID of the user.
  final String userId;

  /// Role of the member within the group.
  final GroupRole role;

  /// When the member joined the group.
  final DateTime joinedAt;

  /// Full name of the member (if available).
  final String? fullName;

  /// URL of the member's profile image (if available).
  final String? avatarUrl;

  /// Creates a [GroupMember] instance.
  GroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.fullName,
    this.avatarUrl,
  });

  /// Creates a [GroupMember] from a JSON map.
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      groupId: json['group_id'],
      userId: json['user_id'],
      role: GroupRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => GroupRole.member,
      ),
      joinedAt: DateTime.parse(json['joined_at']),
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
    );
  }
}

/// Represents a message sent within a group chat.
class GroupMessage {
  /// Unique identifier of the message.
  final String id;

  /// ID of the group where the message was sent.
  final String groupId;

  /// ID of the user who sent the message.
  final String senderId;

  /// Text content of the message.
  final String content;

  /// When the message was sent.
  final DateTime createdAt;

  /// Name of the sender (cached from profile).
  final String? senderName;

  /// Avatar URL of the sender (cached from profile).
  final String? senderAvatar;

  /// Creates a [GroupMessage] instance.
  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  /// Creates a [GroupMessage] from a JSON map.
  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return GroupMessage(
      id: json['id'],
      groupId: json['group_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      senderName: profile?['full_name'],
      senderAvatar: profile?['avatar_url'],
    );
  }
}

/// Roles within a collaborative learning group.
enum GroupRole {
  /// The creator of the group with full administrative powers.
  owner,

  /// A member with permission to manage messages and members.
  moderator,

  /// A regular participant in the group.
  member;

  /// Whether this role has moderation privileges.
  bool get canModerate => this == owner || this == moderator;

  /// Whether this role is the owner.
  bool get isOwner => this == owner;
}
