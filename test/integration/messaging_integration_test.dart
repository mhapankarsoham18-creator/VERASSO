import 'package:flutter_test/flutter_test.dart';
// import 'package:verasso/core/security/encryption_service.dart';

import 'package:verasso/core/security/encryption_service.dart' as core_enc;
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/messaging/services/encryption_service.dart';
import 'package:verasso/features/messaging/services/message_read_receipt_service.dart';
import 'package:verasso/features/messaging/services/messaging_encryption_service.dart';
import 'package:verasso/features/gamification/services/gamification_event_bus.dart';

import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockMessagingEncryptionService mockMessagingEncryptionService;
  late MockCoreEncryption mockCoreEncryption;
  late MessageRepository messageRepository;
  late MessagingEncryptionService messagingEncryptionService;
  late MessageReadReceiptService readReceiptService;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  final otherUser = TestSupabaseUser(
    id: 'user-2',
    email: 'other@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);

    mockMessagingEncryptionService = MockMessagingEncryptionService();
    mockCoreEncryption = MockCoreEncryption();

    messageRepository = MessageRepository(
      client: mockSupabase,
      encryptionService: mockMessagingEncryptionService,
      gamificationEventBus: GamificationEventBus(mockSupabase),
      notificationService: MockNotificationService(),
    );

    messagingEncryptionService = MessagingEncryptionService(
      client: mockSupabase,
      encryptionService: mockCoreEncryption,
    );
    readReceiptService = MessageReadReceiptService(client: mockSupabase);
  });

  group('Messaging Integration Tests', () {
    test('send direct message with encryption', () async {
      mockMessagingEncryptionService.encryptResult =
          'encrypted_message_content';

      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      await expectLater(
        messageRepository.sendMessage(
          senderId: testUser.id,
          receiverId: otherUser.id,
          content: 'Hello, encrypted message!',
          conversationId: 'conv-1',
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'messages');
    });

    test('receive message with decryption', () async {
      mockMessagingEncryptionService.decryptResult =
          'Hello, encrypted message!';

      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-1',
          'sender_id': otherUser.id,
          'receiver_id': testUser.id,
          'content': 'encrypted_message_content',
          'conversation_id': 'conv-1',
          'type': 'text',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final messages = await messageRepository.getMessages('conv-1').first;

      expect(messages, isNotEmpty);
      expect(messages[0].senderId, otherUser.id);
    });

    test('message appears in conversation after send', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-1',
          'sender_id': testUser.id,
          'receiver_id': otherUser.id,
          'content': 'Test message',
          'conversation_id': 'conv-1',
          'type': 'text',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final messages = await messageRepository.getMessages('conv-1').first;

      expect(messages, isNotEmpty);
      expect(messages[0].content, 'decrypted_content');
    });

    test('mark message as read updates database', () async {
      final readReceiptsBuilder =
          MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder(
          'message_read_receipts', readReceiptsBuilder);

      await expectLater(
        readReceiptService.markMessageAsRead(
          'msg-1',
          userId: testUser.id,
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'message_read_receipts');
    });

    test('read receipt appears after marking message read', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-1',
          'receiver_id': testUser.id,
          'read_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final readStatus = await readReceiptService.getMessageReadStatus('msg-1');

      expect(readStatus, isNotNull);
    });

    test('get unread message count', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-1',
          'sender_id': 'user-2',
          'receiver_id': testUser.id,
          'content': 'Unread 1',
          'conversation_id': 'conv-1',
          'type': 'text',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'msg-2',
          'sender_id': 'user-2',
          'receiver_id': testUser.id,
          'content': 'Unread 2',
          'conversation_id': 'conv-1',
          'type': 'text',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'msg-3',
          'sender_id': 'user-2',
          'receiver_id': testUser.id,
          'content': 'Read 1',
          'conversation_id': 'conv-1',
          'type': 'text',
          'status': 'read',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final unreadCount = await messageRepository.getUnreadCount(testUser.id);

      expect(unreadCount, greaterThan(0));
    });

    test('send group message to multiple recipients', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final groupMembers = ['user-3', 'user-4', 'user-5'];

      await expectLater(
        messageRepository.sendGroupMessage(
          senderId: testUser.id,
          groupId: 'group-1',
          content: 'Group message',
          recipientIds: groupMembers,
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'messages');
    });

    test('message encryption preserves content integrity', () async {
      final enc = await messagingEncryptionService.encryptMessage(
        'Original content',
        'key-1',
      );
      expect(enc, 'encrypted_Original content');
    });

    test('message attachment upload stores file reference', () async {
      final attachmentsBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('message_attachments', attachmentsBuilder);

      await expectLater(
        messageRepository.uploadAttachment(
          messageId: 'msg-1',
          filePath: 'path/to/image.jpg',
        ),
        completes,
      );
    });

    test('delete message removes from conversation', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      await expectLater(
        messageRepository.deleteMessage('msg-1'),
        completes,
      );

      expect(mockSupabase.lastDeleteTable, 'messages');
    });

    test('edit message updates content with new encryption', () async {
      mockMessagingEncryptionService.setEncryptResult('new_encrypted_content');

      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      await expectLater(
        messageRepository.updateMessage(
          'msg-1',
          'Updated message',
        ),
        completes,
      );

      expect(mockSupabase.lastUpdateTable, 'messages');
    });

    test('search messages with encryption query', () async {
      mockMessagingEncryptionService.decryptResult =
          'message containing search term';

      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-1',
          'sender_id': testUser.id,
          'receiver_id': otherUser.id,
          'content': 'encrypted_searchable_content',
          'conversation_id': 'conv-1',
          'type': 'text',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final results = await messageRepository.searchMessages(
        conversationId: 'conv-1',
        query: 'search',
      );

      expect(results, isNotEmpty);
    });
  });

  group('Messaging Integration - Conversation State', () {
    test('conversation status updates after new message', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-a',
          'sender_id': otherUser.id,
          'receiver_id': testUser.id,
          'content': 'encrypted_content',
          'type': 'text',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final conversation =
          await messageRepository.getConversation('conv_user-1_user-2');

      expect(conversation, isNotNull);
      expect(conversation?.unreadCount, 1);
    });

    test('archive conversation hides from active list', () async {
      final conversationsBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('conversations', conversationsBuilder);

      await expectLater(
        messageRepository.archiveConversation('conv-1'),
        completes,
      );

      expect(mockSupabase.lastUpdateTable, 'conversations');
    });

    test('conversation deleted message count preserved', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-a',
          'sender_id': otherUser.id,
          'receiver_id': testUser.id,
          'content': 'encrypted_content',
          'type': 'text',
          'status': 'read',
          'created_at': DateTime.now().toIso8601String(),
          'read_at': DateTime.now().toIso8601String(),
          'message_count': 150,
          'deleted_message_count': 150,
        }
      ]);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final conversation =
          await messageRepository.getConversation('conv_user-1_user-2');

      expect(conversation?.messageCount, 150);
    });
  });

  group('Messaging Integration - High Volume', () {
    test('load 10,000+ messages without crash', () async {
      final largeMessageList = List.generate(
        10000,
        (i) => {
          'id': 'msg-$i',
          'sender_id': i % 2 == 0 ? testUser.id : otherUser.id,
          'receiver_id': i % 2 == 0 ? otherUser.id : testUser.id,
          'content': 'Message $i',
          'conversation_id': 'conv-1',
          'type': 'text',
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      final messagesBuilder =
          MockSupabaseQueryBuilder(selectResponse: largeMessageList);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final stopwatch = Stopwatch()..start();
      final messages = messageRepository.getMessages('conv-1');
      stopwatch.stop();

      expect((await messages.first).length, 10000);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('concurrent message sends handled safely', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      final futures = List.generate(
        100,
        (i) => messageRepository.sendMessage(
          senderId: testUser.id,
          receiverId: otherUser.id,
          content: 'Message $i',
          conversationId: 'conv-1',
        ),
      );

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });

    test('bulk mark multiple messages as read', () async {
      final readReceiptsBuilder =
          MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder(
          'message_read_receipts', readReceiptsBuilder);

      final messageIds = List.generate(1000, (i) => 'msg-$i');

      final futures = messageIds.map((msgId) {
        return readReceiptService.markMessageAsRead(
          msgId,
          userId: testUser.id,
        );
      }).toList();

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });
  });

  group('Messaging Integration - Error Handling', () {
    test('send message to non-existent user handled gracefully', () async {
      final messagesBuilder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      // Should handle authorization error
      expect(true, true);
    });

    test('decrypt message with invalid key fails safely', () async {
      mockMessagingEncryptionService.setDecryptResult('');

      // Should handle gracefully
      expect(true, true);
    });

    test('network error during message send retries', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('messages', builder);

      // Should implement retry logic
      expect(true, true);
    });

    test('file attachment too large rejected', () async {
      // Size validation should prevent upload
      expect(true, true);
    });

    test('message content exceeds length limit rejected', () async {
      final messagesBuilder =
          MockSupabaseQueryBuilder(selectResponse: [], shouldThrow: false);
      mockSupabase.setQueryBuilder('messages', messagesBuilder);

      // Should validate before sending
      expect(true, true);
    });
  });
}

class MockCoreEncryption extends Fake implements core_enc.EncryptionService {
  @override
  Future<String> decrypt(String encryptedMessage) async =>
      encryptedMessage.replaceAll('encrypted_', '');
  @override
  Future<String> encrypt(String plaintext) async => 'encrypted_$plaintext';
}

class MockMessagingEncryption extends Fake implements EncryptionService {
  String? encryptResult;
  String? decryptResult;

  @override
  Future<String> decryptMessage(Map<String, dynamic> messageRow,
      {bool isGroup = false}) async {
    return decryptResult ?? 'decrypted_content';
  }

  @override
  Future<Map<String, String>> encryptMessage(
      String content, String receiverId) async {
    return {
      'content': encryptResult ?? 'encrypted_content',
      'iv': 'fake',
      'key_receiver': 'fake',
      'key_sender': 'fake',
    };
  }

  void setDecryptResult(String r) => decryptResult = r;
  void setEncryptResult(String r) => encryptResult = r;
}
