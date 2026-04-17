import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/network/connectivity_provider.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(ref);
  // Auto-trigger sync when transitioning exactly from offline -> online
  ref.listen(connectivityProvider, (previous, next) {
    if (previous == NetworkStatus.offline && next == NetworkStatus.online) {
      engine.flushQueue();
    }
  });
  return engine;
});

class SyncEngine {
  final Ref ref;
  final Box _mutationBox = Hive.box('mutation_queue');

  SyncEngine(this.ref);

  Future<void> queueLike(String postId, int currentLikes) async {
    final status = ref.read(connectivityProvider);
    
    // 1. Optimistic Local Update
    final feedBox = Hive.box('feed_cache');
    if (feedBox.containsKey(postId)) {
      final postData = jsonDecode(feedBox.get(postId));
      postData['likes'] = currentLikes + 1;
      postData['_is_pending_sync'] = status == NetworkStatus.offline;
      feedBox.put(postId, jsonEncode(postData));
    }

    if (status == NetworkStatus.online) {
      // Direct remote update
      try {
        await Supabase.instance.client.rpc('increment_likes', params: {'post_id': postId});
      } catch (e) {
        // Fallback to queue if the API actually failed
        _queueMutation('LIKE', {'post_id': postId});
      }
    } else {
      // Put in queue
      _queueMutation('LIKE', {'post_id': postId});
    }
  }

  void _queueMutation(String type, Map<String, dynamic> payload) {
    _mutationBox.add(jsonEncode({
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String()
    }));
  }

  Future<void> flushQueue() async {
    if (_mutationBox.isEmpty) return;
    
    final keys = _mutationBox.keys.toList();
    for (var key in keys) {
      final task = jsonDecode(_mutationBox.get(key));
      try {
        if (task['type'] == 'LIKE') {
          final postId = task['payload']['post_id'];
          await Supabase.instance.client.rpc('increment_likes', params: {'post_id': postId});
          
          // Clear pending flag
          final feedBox = Hive.box('feed_cache');
          if (feedBox.containsKey(postId)) {
            final postData = jsonDecode(feedBox.get(postId));
            postData.remove('_is_pending_sync');
            feedBox.put(postId, jsonEncode(postData));
          }
        }
        // Successfully flushed
        await _mutationBox.delete(key);
      } catch (e, stackTrace) {
        Sentry.captureException(e, stackTrace: stackTrace);
        debugPrint('Sync failed for task $key, retrying later. ($e)');
      }
    }
  }
}
