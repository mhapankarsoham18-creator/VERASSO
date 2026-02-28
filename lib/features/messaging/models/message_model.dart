/// Represents a chat conversation between two participants.
class Conversation {
  /// Unique identifier of the conversation.
  final String id;

  /// Unique identifier of the first participant.
  final String participant1Id;

  /// Unique identifier of the second participant.
  final String participant2Id;

  /// The most recent message in this conversation.
  final Message? lastMessage;

  /// Count of messages unread by the current user.
  final int unreadCount;

  /// Total count of messages in the conversation.
  final int messageCount;

  /// Count of messages deleted in the conversation.
  final int deletedMessageCount;

  /// The timestamp when the conversation was created.
  final DateTime createdAt;

  /// The timestamp when the conversation was last updated.
  final DateTime? updatedAt;

  /// Creates a [Conversation] instance.
  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.unreadCount = 0,
    this.messageCount = 0,
    this.deletedMessageCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Conversation] for a JSON map.
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participant1Id: json['participant1_id'],
      participant2Id: json['participant2_id'],
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      messageCount: json['message_count'] ?? 0,
      deletedMessageCount: json['deleted_message_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Returns the ID of the participant who is not [currentUserId].
  String getOtherParticipantId(String currentUserId) {
    return participant1Id == currentUserId ? participant2Id : participant1Id;
  }
}

/// Represents a single message within a conversation.
class Message {
  /// Unique identifier of the message.
  final String id;

  /// Unique identifier of the conversation this message belongs to.
  final String conversationId;

  /// Unique identifier of the user who sent the message.
  final String senderId;

  /// Unique identifier of the user who is intended to receive the message (for 1:1).
  final String? receiverId;

  /// Unique identifier of the group this message belongs to (for group chats).
  final String? groupId;

  /// Type category of the message (e.g., text, image).
  final MessageType type;

  /// The decrypted content of the message or a media URL.
  final String content;

  /// The encrypted content of the message for end-to-end encryption.
  final String? encryptedContent;

  /// The current status of the message (e.g., sent, delivered).
  final MessageStatus status;

  /// The timestamp when the message was sent.
  final DateTime sentAt;

  /// The timestamp when the message was read by the recipient.
  final DateTime? readAt;

  /// Whether the message is masked for privacy.
  final bool isShielded;

  /// Additional structured information about the message.
  final Map<String, dynamic>? metadata;

  /// Creates a [Message] instance.
  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.receiverId,
    this.groupId,
    required this.type,
    required this.content,
    this.encryptedContent,
    required this.status,
    required this.sentAt,
    this.readAt,
    this.isShielded = false,
    this.metadata,
  });

  /// Creates a [Message] from a JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      groupId: json['group_id'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      content: json['content'],
      encryptedContent: json['encrypted_content'],
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
      sentAt: DateTime.parse(json['sent_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      isShielded: json['is_shielded'] ?? false,
      metadata: json['metadata'],
    );
  }

  /// Creates a copy of [Message] with optional field overrides.
  Message copyWith({
    MessageStatus? status,
    DateTime? readAt,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      groupId: groupId,
      type: type,
      content: content,
      encryptedContent: encryptedContent,
      status: status ?? this.status,
      sentAt: sentAt,
      readAt: readAt ?? this.readAt,
      isShielded: isShielded,
      metadata: metadata,
    );
  }

  /// Converts the [Message] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'group_id': groupId,
      'type': type.name,
      'content': content,
      'encrypted_content': encryptedContent,
      'status': status.name,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'is_shielded': isShielded,
      'metadata': metadata,
    };
  }
}

/// Current delivery or read status of a message.
enum MessageStatus {
  /// Message is being transmitted.
  sending,

  /// Message has reached the server.
  sent,

  /// Message has been delivered to the recipient's device.
  delivered,

  /// Recipient has opened and read the message.
  read,

  /// Transmission failed.
  failed,
}

/// Categorization of message content types.
enum MessageType {
  /// Simple text content.
  text,

  /// Static or animated image.
  image,

  /// Video file or stream.
  video,

  /// Audio recording or stream.
  audio,

  /// Rich sticker element.
  sticker,

  /// Dynamic GIF image.
  gif,
}
