import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/messaging/models/message_model.dart';
import 'package:verasso/features/messaging/services/message_service.dart';

void main() {
  late MockMessageRepository mockRepo;
  late MessageService messageService;

  setUp(() {
    mockRepo = MockMessageRepository();
    messageService = MessageService(mockRepo);
  });

  group('MessageService — sendMessage', () {
    test('sends a text message and returns it', () async {
      final msg = await messageService.sendMessage(
        content: 'Hello!',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      expect(msg, isNotNull);
      expect(msg.content, 'Hello!');
      expect(msg.senderId, 'user-1');
      expect(msg.status, MessageStatus.sent);
    });

    test('throws on empty content', () async {
      expect(
        () => messageService.sendMessage(
          content: '',
          senderId: 'user-1',
          recipientId: 'user-2',
        ),
        throwsException,
      );
    });

    test('sends multiple messages and retrieves them', () async {
      await messageService.sendMessage(
        content: 'First',
        senderId: 'user-1',
        recipientId: 'user-2',
      );
      await messageService.sendMessage(
        content: 'Second',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      final msgs = await messageService.getInboxMessages('user-1');
      expect(msgs.length, 2);
    });
  });

  group('MessageService — getInboxMessages', () {
    test('returns list of messages', () async {
      await messageService.sendMessage(
        content: 'msg1',
        senderId: 'user-1',
        recipientId: 'user-2',
      );
      await messageService.sendMessage(
        content: 'msg2',
        senderId: 'user-2',
        recipientId: 'user-1',
      );

      final inbox = await messageService.getInboxMessages('user-1');
      expect(inbox.length, 2);
    });

    test('returns empty list when no messages', () async {
      final inbox = await messageService.getInboxMessages('user-1');
      expect(inbox, isEmpty);
    });
  });

  group('MessageService — getUnreadCount', () {
    test('counts unread messages for user', () async {
      await messageService.sendMessage(
        content: 'unread1',
        senderId: 'user-1',
        recipientId: 'user-2',
      );
      await messageService.sendMessage(
        content: 'unread2',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      final count = await messageService.getUnreadCount('user-2');
      expect(count, 2);
    });
  });

  group('MessageService — searchMessages', () {
    test('searches messages by content', () async {
      await messageService.sendMessage(
        content: 'Hello World',
        senderId: 'user-1',
        recipientId: 'user-2',
      );
      await messageService.sendMessage(
        content: 'Goodbye',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      final results = await messageService.searchMessages('user-1', 'Hello');
      expect(results.length, 1);
      expect(results.first.content, 'Hello World');
    });
  });

  group('MessageService — archiveMessage', () {
    test('archives without error', () async {
      await expectLater(
        messageService.archiveMessage('msg-1'),
        completes,
      );
    });

    test('unarchives without error', () async {
      await expectLater(
        messageService.unarchiveMessage('msg-1'),
        completes,
      );
    });
  });

  group('Message model', () {
    test('fromJson creates correct message', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'u1',
        'receiver_id': 'u2',
        'type': 'text',
        'content': 'Hello',
        'status': 'sent',
        'sent_at': '2026-02-27T12:00:00Z',
      };

      final msg = Message.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.content, 'Hello');
      expect(msg.type, MessageType.text);
      expect(msg.status, MessageStatus.sent);
    });

    test('toJson roundtrips correctly', () {
      final msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'u1',
        receiverId: 'u2',
        type: MessageType.text,
        content: 'Test',
        status: MessageStatus.sent,
        sentAt: DateTime.parse('2026-02-27T12:00:00Z'),
      );

      final json = msg.toJson();
      expect(json['id'], 'msg-1');
      expect(json['content'], 'Test');
      expect(json['type'], 'text');
    });

    test('copyWith updates status', () {
      final msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'u1',
        type: MessageType.text,
        content: 'Test',
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
      );

      final read =
          msg.copyWith(status: MessageStatus.read, readAt: DateTime.now());
      expect(read.status, MessageStatus.read);
      expect(read.readAt, isNotNull);
      expect(read.content, 'Test'); // Unchanged
    });
  });

  group('Conversation model', () {
    test('fromJson creates conversation', () {
      final json = {
        'id': 'conv-1',
        'participant1_id': 'u1',
        'participant2_id': 'u2',
        'created_at': '2026-02-27T12:00:00Z',
        'unread_count': 5,
      };

      final conv = Conversation.fromJson(json);
      expect(conv.id, 'conv-1');
      expect(conv.unreadCount, 5);
    });

    test('getOtherParticipantId returns correct user', () {
      final conv = Conversation(
        id: 'conv-1',
        participant1Id: 'u1',
        participant2Id: 'u2',
        createdAt: DateTime.now(),
      );

      expect(conv.getOtherParticipantId('u1'), 'u2');
      expect(conv.getOtherParticipantId('u2'), 'u1');
    });
  });
}

/// A mock MessageRepository for testing MessageService without Supabase.
class MockMessageRepository extends Fake implements MessageRepository {
  final List<Message> _messages = [];
  bool shouldThrow = false;

  @override
  Future<void> archiveConversation(String conversationId) async {
    if (shouldThrow) throw Exception('Archive failed');
  }

  @override
  Future<List<Message>> getMessagesList(String conversationId) async {
    if (shouldThrow) throw Exception('Fetch failed');
    return _messages;
  }

  @override
  Future<int> getUnreadCount([String? userId]) async {
    if (shouldThrow) throw Exception('Count failed');
    if (userId == null) {
      return _messages.where((m) => m.status != MessageStatus.read).length;
    }
    return _messages
        .where((m) => m.receiverId == userId && m.status != MessageStatus.read)
        .length;
  }

  @override
  Future<void> markAsRead(String messageId) async {
    if (shouldThrow) throw Exception('Mark read failed');
  }

  @override
  Future<List<Message>> searchMessages(
      {String? conversationId, required String query}) async {
    if (shouldThrow) throw Exception('Search failed');
    return _messages.where((m) => m.content.contains(query)).toList();
  }

  @override
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    String? recipientId,
    required String content,
    String? conversationId,
    String mediaType = 'text',
  }) async {
    if (shouldThrow) throw Exception('Send failed');
    _messages.add(Message(
      id: 'msg-${_messages.length + 1}',
      conversationId:
          conversationId ?? 'conv_${[senderId, receiverId]..sort()}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sent,
      sentAt: DateTime.now(),
    ));
  }

  @override
  Future<void> unarchiveConversation(String conversationId) async {
    if (shouldThrow) throw Exception('Unarchive failed');
  }
}
