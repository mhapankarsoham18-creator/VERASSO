import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref);
});

// A robust repository that stitches the live server with the offline cache
class FeedRepository {
  final Ref ref;
  final Box _feedBox = Hive.box('feed_cache');

  FeedRepository(this.ref);

  Stream<List<Map<String, dynamic>>> getFeedStream() async* {
    // 1. Immediately emit offline data from local disk to prevent loading screens
    final localPosts = _feedBox.values.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    if (localPosts.isNotEmpty) {
      localPosts.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
      yield localPosts;
    }

    bool isOffline = false;

    // 2. Fetch live data from the server as primary data source
    try {
      final data = await Supabase.instance.client
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      
      if (data.isNotEmpty) {
        _feedBox.clear();
        for (final doc in data) {
          _feedBox.put(doc['id'], jsonEncode(doc));
        }
        yield List<Map<String, dynamic>>.from(data);
      } else if (localPosts.isEmpty) {
        // No data anywhere
        yield [];
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      debugPrint('Feed fetch error: $e');
      isOffline = true;
      // If we have no local data either, yield empty
      if (localPosts.isEmpty) {
        yield [];
      }
    }

    // 3. Keep emitting live updates via realtime stream
    if (!isOffline) {
      try {
        yield* Supabase.instance.client
            .from('posts')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .handleError((e, stackTrace) {
              Sentry.captureException(e, stackTrace: stackTrace);
              debugPrint('Realtime stream async error: $e');
            })
            .map((data) {
              for (final doc in data) {
                _feedBox.put(doc['id'], jsonEncode(doc));
              }
              return data;
            });
      } catch (e, stackTrace) {
        Sentry.captureException(e, stackTrace: stackTrace);
        debugPrint('Realtime stream error: $e');
      }
    }
  }
}
