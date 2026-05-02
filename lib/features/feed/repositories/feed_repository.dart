import 'dart:convert';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:verasso/core/utils/logger.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref);
});

// A robust repository that stitches the live server with the offline cache
class FeedRepository {
  final Ref? ref;
  final Box _feedBox;
  final SupabaseClient _supabase;

  FeedRepository([this.ref, Box? feedBox, SupabaseClient? supabaseClient]) 
      : _feedBox = feedBox ?? Hive.box('feed_cache'),
        _supabase = supabaseClient ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMorePosts({required int offset, int limit = 20}) async {
    final data = await _supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    if (data.isNotEmpty) {
      for (final doc in data) {
        _feedBox.put(doc['id'], jsonEncode(doc));
      }
    }
    return List<Map<String, dynamic>>.from(data);
  }

  Stream<List<Map<String, dynamic>>> getFeedStream({int limit = 50}) async* {
    // 1. Immediately emit offline data from local disk to prevent loading screens
    final localPosts = _feedBox.values.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    if (localPosts.isNotEmpty) {
      localPosts.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
      yield localPosts;
    }

    bool isOffline = false;

    // 2. Fetch live data from the server as primary data source
    try {
      final data = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      
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
      appLogger.d('Feed fetch error: $e');
      isOffline = true;
      // If we have no local data either, yield empty
      if (localPosts.isEmpty) {
        yield [];
      }
    }

    // 3. Keep emitting live updates via realtime stream
    if (!isOffline) {
      try {
        yield* _supabase
            .from('posts')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .handleError((e, stackTrace) {
              Sentry.captureException(e, stackTrace: stackTrace);
              appLogger.d('Realtime stream async error: $e');
            })
            .map((data) {
              for (final doc in data) {
                _feedBox.put(doc['id'], jsonEncode(doc));
              }
              return data;
            });
      } catch (e, stackTrace) {
        Sentry.captureException(e, stackTrace: stackTrace);
        appLogger.d('Realtime stream error: $e');
      }
    }
  }

  /// Deletes a post by calling a SECURITY DEFINER RPC that validates
  /// ownership via firebase_uid, bypassing the broken RLS auth.uid() check.
  Future<void> deletePost(String postId) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) throw Exception('Not authenticated');

    await _supabase.rpc('delete_post_safe', params: {
      'p_post_id': postId,
      'p_firebase_uid': firebaseUid,
    });

    // Clean local cache
    _feedBox.delete(postId);
  }
}

