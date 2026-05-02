import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client, FirebaseAuth.instance);
});

class ProfileRepository {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final Box _cache = Hive.box('profile_cache');

  ProfileRepository(this._supabase, this._auth);

  String? get currentFirebaseUid => _auth.currentUser?.uid;

  Future<String?> getMyProfileId() async {
    final uid = currentFirebaseUid;
    if (uid == null) return null;
    
    try {
      final me = await _supabase
          .from('profiles')
          .select('id')
          .eq('firebase_uid', uid)
          .maybeSingle();
      if (me != null && me['id'] != null) {
        await _cache.put('my_profile_id', me['id']);
        return me['id'] as String;
      }
    } catch (e) {
      if (_cache.containsKey('my_profile_id')) {
        return _cache.get('my_profile_id') as String;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProfileById(String profileId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();
      if (data != null) {
        await _cache.put('profile_$profileId', jsonEncode(data));
      }
      return data;
    } catch (e) {
      if (_cache.containsKey('profile_$profileId')) {
        return jsonDecode(_cache.get('profile_$profileId')) as Map<String, dynamic>;
      }
      throw Exception('Offline: Profile not found locally.');
    }
  }

  Future<List<Map<String, dynamic>>> getPostsByAuthorId(String authorId) async {
    try {
      final data = await _supabase
          .from('posts')
          .select()
          .eq('author_id', authorId)
          .order('created_at', ascending: false);
      final List<Map<String, dynamic>> typedData = List<Map<String, dynamic>>.from(data);
      await _cache.put('posts_$authorId', jsonEncode(typedData));
      return typedData;
    } catch (e) {
       if (_cache.containsKey('posts_$authorId')) {
        final List<dynamic> raw = jsonDecode(_cache.get('posts_$authorId'));
        return raw.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    }
  }

  Future<int> getFollowersCount(String profileId) async {
    try {
      final res = await _supabase
          .from('follows')
          .select('id')
          .eq('following_id', profileId)
          .eq('status', 'accepted');
      return res.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getFollowingCount(String profileId) async {
    try {
      final res = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', profileId)
          .eq('status', 'accepted');
      return res.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getPendingRequestsCount(String profileId) async {
    try {
      final res = await _supabase
          .from('follows')
          .select('id')
          .eq('following_id', profileId)
          .eq('status', 'pending');
      return res.length;
    } catch (e) {
      return 0;
    }
  }

  Future<String> getFollowStatus(String myId, String targetId) async {
    try {
      final follow = await _supabase
          .from('follows')
          .select('status')
          .eq('follower_id', myId)
          .eq('following_id', targetId)
          .maybeSingle();
      return follow?['status'] as String? ?? 'none';
    } catch (e) {
      return 'none';
    }
  }

  Future<void> sendFollowRequest(String myId, String targetId) async {
    await _supabase.from('follows').insert({
      'follower_id': myId,
      'following_id': targetId,
      'status': 'pending',
    });
  }

  Future<void> unfollow(String myId, String targetId) async {
    await _supabase.from('follows')
        .delete()
        .eq('follower_id', myId)
        .eq('following_id', targetId);
  }

  Future<void> deletePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _supabase.rpc('delete_post_safe', params: {
      'p_post_id': postId,
      'p_firebase_uid': user.uid,
    });
  }
}
