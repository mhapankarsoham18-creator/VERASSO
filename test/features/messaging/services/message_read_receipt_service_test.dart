import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/messaging/services/message_read_receipt_service.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MessageReadReceiptService service;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    service = MessageReadReceiptService(client: mockSupabase);
  });

  group('MessageReadReceiptService Tests', () {
    test('getConversationReadStats returns correct statistics', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {'id': 'msg-1', 'read_at': null},
        {'id': 'msg-2', 'read_at': '2025-01-15T10:00:00Z'},
        {'id': 'msg-3', 'read_at': '2025-01-15T11:00:00Z'},
      ]);
      mockSupabase.setQueryBuilder('messages', builder);

      final stats = await service.getConversationReadStats('conv-1');

      expect(stats, isNotNull);
      expect(stats?.conversationId, 'conv-1');
      expect(stats?.totalMessages, 3);
      expect(stats?.readMessages, 2);
      expect(stats?.unreadMessages, 1);
      expect(stats?.readPercentage, closeTo(66.67, 0.1));
    });

    test('getConversationReadStats returns null when conversation not found',
        () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('messages', builder);

      final stats = await service.getConversationReadStats('nonexistent-conv');

      expect(stats, isNull);
    });

    test('getMessageReadStatus returns status for existing message', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-1',
          'read_at': '2025-01-15T10:30:00Z',
          'receiver_id': 'user-2',
          'created_at': '2025-01-15T10:00:00Z',
        }
      ]);
      mockSupabase.setQueryBuilder('messages', builder);

      final status = await service.getMessageReadStatus('msg-1');

      expect(status, isNotNull);
      expect(status?.messageId, 'msg-1');
      expect(status?.receiverId, 'user-2');
      expect(status?.isRead, true);
    });

    test('getMessageReadStatus returns null for missing message', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('messages', builder);

      final status = await service.getMessageReadStatus('nonexistent-msg');

      expect(status, isNull);
    });

    test('getMessagesReadStatus returns status for multiple messages',
        () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'msg-1',
          'read_at': '2025-01-15T10:30:00Z',
          'receiver_id': 'user-2',
          'created_at': '2025-01-15T10:00:00Z',
        },
        {
          'id': 'msg-2',
          'read_at': null,
          'receiver_id': 'user-2',
          'created_at': '2025-01-15T10:10:00Z',
        }
      ]);
      mockSupabase.setQueryBuilder('messages', builder);

      final statuses = await service.getMessagesReadStatus(['msg-1', 'msg-2']);

      expect(statuses, hasLength(2));
      expect(statuses[0].isRead, true);
      expect(statuses[1].isRead, false);
    });

    test('getMessagesReadStatus returns empty list on error', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('messages', builder);

      final statuses =
          await service.getMessagesReadStatus(['msg-1', 'msg-2']);

      expect(statuses, isEmpty);
    });

    test('getReadMessageIds returns list of read message IDs', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {'id': 'msg-1'},
        {'id': 'msg-2'},
      ]);
      mockSupabase.setQueryBuilder('messages', builder);

      final readIds = await service.getReadMessageIds('conv-1');

      expect(readIds, containsAll(['msg-1', 'msg-2']));
    });

    test('getReadMessageIds returns empty list on error', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('messages', builder);

      final readIds = await service.getReadMessageIds('conv-1');

      expect(readIds, isEmpty);
    });

    test('getTotalUnreadCount returns count for current user', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: [],
        countResponse: 5,
      );
      mockSupabase.setQueryBuilder('messages', builder);

      final count = await service.getTotalUnreadCount();

      expect(count, 5);
    });

    test('getTotalUnreadCount throws when user not authenticated', () async {
      mockAuth.setCurrentUser(null);

      expect(
        () => service.getTotalUnreadCount(),
        throwsException,
      );
    });

    test('getTotalUnreadCount returns 0 on error', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('messages', builder);

      final count = await service.getTotalUnreadCount();

      expect(count, 0);
    });

    test('getUnreadCount returns count for specific conversation', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: [],
        countResponse: 3,
      );
      mockSupabase.setQueryBuilder('messages', builder);

      final count = await service.getUnreadCount('conv-1');

      expect(count, 3);
    });

    test('getUnreadCountsByConversation returns map of unread counts',
        () async {
      mockSupabase.setRpcResponse('get_unread_message_count', [
        {'conversation_id': 'conv-1', 'unread_count': 2},
        {'conversation_id': 'conv-2', 'unread_count': 5},
      ]);

      final counts = await service.getUnreadCountsByConversation();

      expect(counts, {'conv-1': 2, 'conv-2': 5});
    });

    test('getUnreadCountsByConversation returns empty map on error', () async {
      mockSupabase.setRpcResponse(
        'get_unread_message_count',
        null,
        shouldThrow: true,
      );

      final counts = await service.getUnreadCountsByConversation();

      expect(counts, isEmpty);
    });

    test('markConversationAsRead updates messages to read', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('messages', builder);

      await expectLater(
        service.markConversationAsRead('conv-1'),
        completes,
      );
    });

    test('markConversationAsRead throws when user not authenticated',
        () async {
      mockAuth.setCurrentUser(null);

      expect(
        () => service.markConversationAsRead('conv-1'),
        throwsException,
      );
    });

    test('markMessageAsRead marks specific message as read', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('messages', builder);

      await expectLater(
        service.markMessageAsRead('msg-1'),
        completes,
      );
    });

    test('markMessageAsRead throws when user not authenticated', () async {
      mockAuth.setCurrentUser(null);

      expect(
        () => service.markMessageAsRead('msg-1'),
        throwsException,
      );
    });

    test('streamConversationReadReceipts returns stream of read statuses',
        () async {
      final mockStream = Stream<List<Map<String, dynamic>>>.fromIterable([
        [
          {
            'id': 'msg-1',
            'read_at': '2025-01-15T10:30:00Z',
            'receiver_id': 'user-2',
            'created_at': '2025-01-15T10:00:00Z',
          }
        ]
      ]);

      mockSupabase.setStreamResponse('messages', mockStream);

      final stream = service.streamConversationReadReceipts('conv-1');
      final statuses = await stream.first;

      expect(statuses, isNotEmpty);
      expect(statuses[0].messageId, 'msg-1');
      expect(statuses[0].isRead, true);
    });
  });

  group('MessageReadStatus Model Tests', () {
    test('MessageReadStatus.isRead returns true when readAt is set', () {
      final status = MessageReadStatus(
        messageId: 'msg-1',
        readAt: DateTime(2025, 1, 15, 10, 30),
        receiverId: 'user-2',
        createdAt: DateTime(2025, 1, 15, 10, 0),
      );

      expect(status.isRead, true);
    });

    test('MessageReadStatus.isRead returns false when readAt is null', () {
      final status = MessageReadStatus(
        messageId: 'msg-1',
        readAt: null,
        receiverId: 'user-2',
        createdAt: DateTime(2025, 1, 15, 10, 0),
      );

      expect(status.isRead, false);
    });

    test('MessageReadStatus.readDelay calculates time difference', () {
      final created = DateTime(2025, 1, 15, 10, 0);
      final read = DateTime(2025, 1, 15, 10, 30);
      final status = MessageReadStatus(
        messageId: 'msg-1',
        readAt: read,
        receiverId: 'user-2',
        createdAt: created,
      );

      expect(status.readDelay, Duration(minutes: 30));
    });

    test('MessageReadStatus.readDelay returns null when unread', () {
      final status = MessageReadStatus(
        messageId: 'msg-1',
        readAt: null,
        receiverId: 'user-2',
        createdAt: DateTime(2025, 1, 15, 10, 0),
      );

      expect(status.readDelay, null);
    });
  });

  group('ConversationReadStats Model Tests', () {
    test('ConversationReadStats calculates all statistics correctly', () {
      final stats = ConversationReadStats(
        conversationId: 'conv-1',
        totalMessages: 10,
        readMessages: 7,
        unreadMessages: 3,
        readPercentage: 70.0,
      );

      expect(stats.conversationId, 'conv-1');
      expect(stats.totalMessages, 10);
      expect(stats.readMessages, 7);
      expect(stats.unreadMessages, 3);
      expect(stats.readPercentage, 70.0);
    });

    test('ConversationReadStats toString includes all fields', () {
      final stats = ConversationReadStats(
        conversationId: 'conv-1',
        totalMessages: 10,
        readMessages: 7,
        unreadMessages: 3,
        readPercentage: 70.0,
      );

      final str = stats.toString();
      expect(str, contains('Total: 10'));
      expect(str, contains('Read: 7'));
      expect(str, contains('Unread: 3'));
      expect(str, contains('70.0%'));
    });
  });
}
