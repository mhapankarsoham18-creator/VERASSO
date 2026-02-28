import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

/// Repository for managing real-time user presence and typing indicators using Supabase Realtime.
class PresenceRepository {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  /// Creates a [PresenceRepository] instance.
  PresenceRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // --- Real-time Presence ---

  /// Joins a presence channel for a specific conversation/activity and tracks online status.
  void joinPresence(
      String userId, String channelId, void Function(List<String>) onSync) {
    // Leave previous if any
    leavePresence();

    _channel = _client.channel('presence-$channelId',
        opts: const RealtimeChannelConfig(self: true));

    _channel!.onPresenceSync((_) {
      final dynamic state = _channel!.presenceState();
      final List<String> onlineUsers = [];

      if (state is List) {
        for (final dynamic presence in state) {
          final dynamic payload = presence.payload;
          if (payload != null &&
              payload is Map &&
              payload.containsKey('user_id')) {
            onlineUsers.add(payload['user_id'].toString());
          }
        }
      }

      onSync(onlineUsers.toSet().toList());
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track(
            {'user_id': userId, 'online_at': DateTime.now().toIso8601String()});
      }
    });
  }

  /// Leaves the current presence channel and stops tracking.
  void leavePresence() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  /// Broadcasts a typing indicator event to a conversation channel.
  void sendTyping(String conversationId, String userId, bool isTyping) {
    // ignore: invalid_use_of_internal_member
    (_client.channel('typing-$conversationId') as dynamic).send(
      type: 'broadcast',
      event: 'typing',
      payload: {'user_id': userId, 'isTyping': isTyping},
    );
  }

  // --- Typing Indicators ---

  /// Returns a stream of typing status for a specific peer in a conversation.
  Stream<bool> watchTyping(String conversationId, String otherUserId) {
    final controller = StreamController<bool>();
    final channel = _client.channel('typing-$conversationId');

    channel
        .onBroadcast(
            event: 'typing',
            callback: (payload) {
              if (payload['user_id'] == otherUserId) {
                controller.add(payload['isTyping'] as bool? ?? false);
              }
            })
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
