import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/services/supabase_service.dart';

// Stream conversation read receipts
/// Stream provider for conversation read receipts.
final conversationReadReceiptsStreamProvider =
    StreamProvider.family<List<MessageReadStatus>, String>(
  (ref, conversationId) {
    final service = ref.watch(messageReadReceiptProvider);
    return service.streamConversationReadReceipts(conversationId);
  },
);

// Watch unread count for a conversation
/// Future provider for the unread message count of a specific conversation.
final conversationUnreadCountProvider =
    FutureProvider.family<int, String>((ref, conversationId) {
  final service = ref.watch(messageReadReceiptProvider);
  return service.getUnreadCount(conversationId);
});

// Riverpod Providers
/// Provider for the [MessageReadReceiptService] instance.
final messageReadReceiptProvider = Provider((ref) {
  return MessageReadReceiptService();
});

// Watch total unread count
/// Future provider for the total unread message count across all conversations.
final totalUnreadCountProvider = FutureProvider<int>((ref) {
  final service = ref.watch(messageReadReceiptProvider);
  return service.getTotalUnreadCount();
});

// Watch unread counts per conversation
/// Future provider for a map of unread counts keyed by conversation ID.
final unreadCountsByConversationProvider =
    FutureProvider<Map<String, int>>((ref) {
  final service = ref.watch(messageReadReceiptProvider);
  return service.getUnreadCountsByConversation();
});

/// Conversation Read Statistics
class ConversationReadStats {
  /// Unique identifier for the conversation.
  final String conversationId;

  /// Total number of messages in the conversation.
  final int totalMessages;

  /// Number of messages that have been read.
  final int readMessages;

  /// Number of messages that remain unread.
  final int unreadMessages;

  /// Percentage of messages that have been read (0.0 to 100.0).
  final double readPercentage;

  /// Creates a [ConversationReadStats] instance.
  ConversationReadStats({
    required this.conversationId,
    required this.totalMessages,
    required this.readMessages,
    required this.unreadMessages,
    required this.readPercentage,
  });

  @override
  String toString() {
    return '''
ConversationReadStats(
  Total: $totalMessages,
  Read: $readMessages,
  Unread: $unreadMessages,
  Read%: ${readPercentage.toStringAsFixed(1)}%
)
''';
  }
}

/// Message Read Receipt Service
/// Tracks and manages read/unread status for messages
class MessageReadReceiptService {
  final SupabaseClient _client;

  /// Creates a [MessageReadReceiptService] instance.
  MessageReadReceiptService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Get delivery and read statistics for a conversation
  /// Returns delivery and read statistics for a specific conversation.
  Future<ConversationReadStats?> getConversationReadStats(
      String conversationId) async {
    try {
      final response = await _client
          .from('messages')
          .select('id, read_at')
          .eq('conversation_id', conversationId);

      if (response.isEmpty) return null;

      final messages = response as List;
      final totalMessages = messages.length;
      final readMessages = messages.where((m) => m['read_at'] != null).length;

      return ConversationReadStats(
        conversationId: conversationId,
        totalMessages: totalMessages,
        readMessages: readMessages,
        unreadMessages: totalMessages - readMessages,
        readPercentage:
            totalMessages > 0 ? (readMessages / totalMessages) * 100 : 0,
      );
    } catch (e) {
      AppLogger.info('Get conversation read stats error: $e');
      return null;
    }
  }

  /// Get read status for a single message
  /// Returns the read status for a specific message.
  Future<MessageReadStatus?> getMessageReadStatus(String messageId) async {
    try {
      final response = await _client
          .from('messages')
          .select('id, read_at, receiver_id, created_at')
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return null;

      return MessageReadStatus(
        messageId: messageId,
        readAt: response['read_at'] != null
            ? DateTime.parse(response['read_at'] as String)
            : null,
        receiverId: response['receiver_id'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
    } catch (e) {
      AppLogger.info('Get message read status error: $e');
      return null;
    }
  }

  /// Get read status for multiple messages
  /// Returns read status for a batch of messages.
  Future<List<MessageReadStatus>> getMessagesReadStatus(
      List<String> messageIds) async {
    try {
      final responses = await _client
          .from('messages')
          .select('id, read_at, receiver_id, created_at')
          .inFilter('id', messageIds);

      return (responses as List)
          .map((r) => MessageReadStatus(
                messageId: r['id'] as String,
                readAt: r['read_at'] != null
                    ? DateTime.parse(r['read_at'] as String)
                    : null,
                receiverId: r['receiver_id'] as String,
                createdAt: DateTime.parse(r['created_at'] as String),
              ))
          .toList();
    } catch (e) {
      AppLogger.info('Get messages read status error: $e');
      return [];
    }
  }

  /// Get messages that have been read (for sender view)
  /// Returns IDs of messages that have been read in a conversation.
  Future<List<String>> getReadMessageIds(String conversationId) async {
    try {
      final response = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .not('read_at', 'is', null);

      return (response as List).map((r) => r['id'] as String).toList();
    } catch (e) {
      AppLogger.info('Get read message IDs error: $e');
      return [];
    }
  }

  /// Get unread count across all conversations
  /// Returns the total number of unread messages across all conversations.
  Future<int> getTotalUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .filter('read_at', 'is', null)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      AppLogger.info('Get total unread count error: $e');
      return 0;
    }
  }

  /// Get unread message count for conversation
  /// Returns the number of unread messages in a specific conversation.
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .filter('read_at', 'is', null)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      AppLogger.info('Get unread count error: $e');
      return 0;
    }
  }

  /// Get unread count per conversation (for list view)
  /// Returns a map of unread message counts for all active conversations.
  Future<Map<String, int>> getUnreadCountsByConversation() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.rpc(
        'get_unread_message_count',
        params: {'p_user_id': userId},
      ) as List;

      final counts = <String, int>{};
      for (var item in response) {
        counts[item['conversation_id'] as String] = item['unread_count'] as int;
      }

      return counts;
    } catch (e) {
      AppLogger.info('Get unread counts by conversation error: $e');
      return {};
    }
  }

  /// Mark all messages in conversation as read
  /// Marks all current unread messages in a conversation as read.
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .filter('read_at', 'is', null);

      AppLogger.info('Conversation $conversationId marked as read');
    } catch (e) {
      AppLogger.info('Mark conversation as read error: $e');
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  /// Mark message as read
  /// Marks a specific message as read by the current user.
  Future<void> markMessageAsRead(String messageId, {String? userId}) async {
    try {
      final effectiveUserId = userId ?? _client.auth.currentUser?.id;
      if (effectiveUserId == null) {
        throw Exception('User not authenticated');
      }

      // Update message read_at timestamp
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', messageId)
          .eq('receiver_id', effectiveUserId);

      // Also record in read receipts table if it exists
      try {
        await _client.from('message_read_receipts').insert({
          'message_id': messageId,
          'user_id': effectiveUserId,
          'read_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      AppLogger.info('Message $messageId marked as read');
    } catch (e) {
      AppLogger.info('Mark message as read error: $e');
      throw Exception('Failed to mark message as read: $e');
    }
  }

  /// Stream read receipt updates for a conversation
  /// Returns a stream of read receipt updates for a specific conversation.
  Stream<List<MessageReadStatus>> streamConversationReadReceipts(
      String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((records) {
          return (records as List)
              .map((r) => MessageReadStatus(
                    messageId: r['id'] as String,
                    readAt: r['read_at'] != null
                        ? DateTime.parse(r['read_at'] as String)
                        : null,
                    receiverId: r['receiver_id'] as String,
                    createdAt: DateTime.parse(r['created_at'] as String),
                  ))
              .toList();
        });
  }
}

/// Message Read Status Model
class MessageReadStatus {
  /// The unique identifier of the message.
  final String messageId;

  /// When the message was read, or null if unread.
  final DateTime? readAt;

  /// The user who received and potentially read the message.
  final String receiverId;

  /// When the message was originally created.
  final DateTime createdAt;

  /// Creates a [MessageReadStatus] instance.
  MessageReadStatus({
    required this.messageId,
    required this.readAt,
    required this.receiverId,
    required this.createdAt,
  });

  /// Whether the message has been read.
  bool get isRead => readAt != null;

  /// The duration between message creation and read timestamp.
  Duration? get readDelay => isRead ? readAt!.difference(createdAt) : null;
}
