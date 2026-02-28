import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/messaging/models/message_model.dart';
import 'package:verasso/features/messaging/services/message_service.dart';

import '../../../mocks.dart';

void main() {
  late MessageService messageService;

  setUp(() {
    final mockRepo = MockMessageRepository();
    final List<Message> messages = [];
    final Set<String> archived = {};

    mockRepo.sendMessageStub = ({
      required String senderId,
      required String receiverId,
      required String content,
    }) async {
      messages.add(Message(
        id: 'msg-${messages.length}',
        conversationId: 'temp',
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: MessageType.text,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
      ));
    };

    mockRepo.getMessagesListStub = (id) async {
      if (id == 'inbox') {
        return messages.where((m) => !archived.contains(m.id)).toList();
      }
      if (id == 'archived') {
        return messages.where((m) => archived.contains(m.id)).toList();
      }
      return messages;
    };

    mockRepo.getUnreadCountStub = ([userId]) async => messages
        .where((m) => m.receiverId == userId && m.status != MessageStatus.read)
        .length;

    mockRepo.searchMessagesStub = ({conversationId, required query}) async {
      return messages.where((m) => m.content.contains(query)).toList();
    };

    mockRepo.archiveConversationStub = (id) async {
      archived.add(id);
    };

    mockRepo.unarchiveConversationStub = (id) async {
      archived.remove(id);
    };

    mockRepo.markAsReadStub = (id) async {
      final idx = messages.indexWhere((m) => m.id == id);
      if (idx != -1) {
        messages[idx] = messages[idx].copyWith(status: MessageStatus.read);
      }
    };

    messageService = MessageService(mockRepo);
  });

  tearDown(() {
    // Cleanup
  });

  group('Message Service - Send Messages', () {
    test('send message with valid content', () async {
      const content = 'Hello, this is a test message';
      const recipientId = 'user-456';
      const senderId = 'user-123';

      final message = await messageService.sendMessage(
        content: content,
        senderId: senderId,
        recipientId: recipientId,
      );

      expect(message, isNotNull);
      expect(message.content, equals(content));
      expect(message.senderId, equals(senderId));
      expect(message.receiverId, equals(recipientId));
    });

    test('send message with empty content fails', () async {
      expect(
        () => messageService.sendMessage(
          content: '',
          senderId: 'user-123',
          recipientId: 'user-456',
        ),
        throwsException,
      );
    });

    test('send message to self is allowed', () async {
      const userId = 'user-789';
      const content = 'Reminder to self';

      final message = await messageService.sendMessage(
        content: content,
        senderId: userId,
        recipientId: userId,
      );

      expect(message.senderId, equals(userId));
      expect(message.receiverId, equals(userId));
    });

    test('message includes timestamp', () async {
      final before = DateTime.now();

      final message = await messageService.sendMessage(
        content: 'Test',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      final after = DateTime.now();

      expect(message.sentAt, isNotNull);
      expect(message.sentAt.isAfter(before.subtract(Duration(seconds: 1))),
          isTrue);
      expect(message.sentAt.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });

    test('message includes unique ID', () async {
      final message1 = await messageService.sendMessage(
        content: 'Message 1',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      final message2 = await messageService.sendMessage(
        content: 'Message 2',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      expect(message1.id, isNot(equals(message2.id)));
    });
  });

  group('Message Service - Read Messages', () {
    test('retrieve sent messages for conversation', () async {
      const userId1 = 'user-1';
      const userId2 = 'user-2';

      await messageService.sendMessage(
        content: 'First message',
        senderId: userId1,
        recipientId: userId2,
      );

      await messageService.sendMessage(
        content: 'Second message',
        senderId: userId2,
        recipientId: userId1,
      );

      final conversation =
          await messageService.getConversation(userId1, userId2);
      expect(conversation, isNotEmpty);
      expect(conversation.length, equals(2));
    });

    test('mark message as read', () async {
      final message = await messageService.sendMessage(
        content: 'Unread message',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      expect(message.status == MessageStatus.read, isFalse);

      final read = await messageService.markAsRead(message.id);
      expect(read.status == MessageStatus.read, isTrue);
    });

    test('get unread message count', () async {
      const userid = 'user-2';

      await messageService.sendMessage(
        content: 'Message 1',
        senderId: 'user-1',
        recipientId: userid,
      );

      await messageService.sendMessage(
        content: 'Message 2',
        senderId: 'user-1',
        recipientId: userid,
      );

      final unreadCount = await messageService.getUnreadCount(userid);
      expect(unreadCount, equals(2));
    });
  });

  group('Message Service - Message Search', () {
    test('search messages by keyword', () async {
      const userId = 'user-1';

      await messageService.sendMessage(
        content: 'Talk about Flutter',
        senderId: userId,
        recipientId: 'user-2',
      );

      await messageService.sendMessage(
        content: 'Discuss Python',
        senderId: userId,
        recipientId: 'user-2',
      );

      final results = await messageService.searchMessages(userId, 'Flutter');
      expect(results, isNotEmpty);
      expect(results.first.content.contains('Flutter'), isTrue);
    });

    test('search with no results returns empty list', () async {
      final results =
          await messageService.searchMessages('user-1', 'nonexistent-word');
      expect(results, isEmpty);
    });
  });

  group('Message Service - Archive Messages', () {
    test('archive message hides from inbox', () async {
      final message = await messageService.sendMessage(
        content: 'Archive me',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      await messageService.archiveMessage(message.id);

      final archivedResults =
          await messageService.getArchivedMessages('user-2');
      expect(archivedResults.any((m) => m.id == message.id), isTrue);
    });

    test('unarchive message returns to inbox', () async {
      final message = await messageService.sendMessage(
        content: 'Test',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      await messageService.archiveMessage(message.id);
      await messageService.unarchiveMessage(message.id);

      final inbox = await messageService.getInboxMessages('user-2');
      expect(inbox.any((m) => m.id == message.id), isTrue);
    });
  });
}
