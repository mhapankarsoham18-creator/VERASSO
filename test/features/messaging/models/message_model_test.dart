import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/messaging/models/message_model.dart';

void main() {
  group('Message Model Tests', () {
    test('fromJson should create valid Message', () {
      final now = DateTime.now();
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'group_id': null,
        'type': 'text',
        'content': 'Hello!',
        'encrypted_content': null,
        'status': 'sent',
        'sent_at': now.toIso8601String(),
        'read_at': null,
        'is_shielded': false,
        'metadata': null,
      };

      final message = Message.fromJson(json);

      expect(message.id, 'msg-1');
      expect(message.senderId, 'user-1');
      expect(message.receiverId, 'user-2');
      expect(message.content, 'Hello!');
      expect(message.type, MessageType.text);
      expect(message.status, MessageStatus.sent);
      expect(message.isShielded, false);
    });

    test('toJson should produce valid map', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Hi there',
        type: MessageType.image,
        status: MessageStatus.delivered,
        sentAt: now,
      );

      final json = message.toJson();

      expect(json['id'], 'msg-1');
      expect(json['type'], 'image');
      expect(json['status'], 'delivered');
      expect(json['sent_at'], now.toIso8601String());
    });

    test('copyWith should override status', () {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'test',
        type: MessageType.text,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
      );

      final updated = message.copyWith(status: MessageStatus.read);

      expect(updated.status, MessageStatus.read);
      expect(updated.content, 'test'); // unchanged
    });

    test('copyWith should set readAt', () {
      final readTime = DateTime.now();
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'test',
        type: MessageType.text,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
      );

      final updated = message.copyWith(readAt: readTime);

      expect(updated.readAt, readTime);
    });
  });

  group('Conversation Model Tests', () {
    test('fromJson should create valid Conversation', () {
      final now = DateTime.now();
      final json = {
        'id': 'conv-1',
        'participant1_id': 'user-1',
        'participant2_id': 'user-2',
        'last_message': {
          'id': 'msg-1',
          'conversation_id': 'conv-1',
          'sender_id': 'user-1',
          'type': 'text',
          'content': 'Last msg',
          'status': 'read',
          'sent_at': now.toIso8601String(),
        },
        'unread_count': 3,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final convo = Conversation.fromJson(json);

      expect(convo.id, 'conv-1');
      expect(convo.participant1Id, 'user-1');
      expect(convo.participant2Id, 'user-2');
      expect(convo.unreadCount, 3);
      expect(convo.lastMessage, isNotNull);
      expect(convo.lastMessage!.content, 'Last msg');
    });

    test('getOtherParticipantId should return correct ID', () {
      final convo = Conversation(
        id: 'conv-1',
        participant1Id: 'user-1',
        participant2Id: 'user-2',
        createdAt: DateTime.now(),
      );

      expect(convo.getOtherParticipantId('user-1'), 'user-2');
      expect(convo.getOtherParticipantId('user-2'), 'user-1');
    });

    test('Conversation with no last message', () {
      final json = {
        'id': 'conv-2',
        'participant1_id': 'a',
        'participant2_id': 'b',
        'unread_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final convo = Conversation.fromJson(json);

      expect(convo.lastMessage, isNull);
      expect(convo.unreadCount, 0);
    });
  });

  group('MessageType enum', () {
    test('should have expected values', () {
      expect(MessageType.values.length, 6);
      expect(MessageType.values, contains(MessageType.text));
      expect(MessageType.values, contains(MessageType.image));
      expect(MessageType.values, contains(MessageType.video));
      expect(MessageType.values, contains(MessageType.audio));
      expect(MessageType.values, contains(MessageType.sticker));
      expect(MessageType.values, contains(MessageType.gif));
    });
  });

  group('MessageStatus enum', () {
    test('should have expected values', () {
      expect(MessageStatus.values.length, 5);
      expect(MessageStatus.values, contains(MessageStatus.sending));
      expect(MessageStatus.values, contains(MessageStatus.sent));
      expect(MessageStatus.values, contains(MessageStatus.delivered));
      expect(MessageStatus.values, contains(MessageStatus.read));
      expect(MessageStatus.values, contains(MessageStatus.failed));
    });
  });
}
