import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/app_exceptions.dart';
import 'profile_lookup_service.dart';

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService(ref);
});

class FollowService {
  final Ref _ref;

  FollowService(this._ref);

  Future<void> sendFollowRequest(String targetProfileId) async {
    final myProfileId = await _ref.read(profileLookupProvider).getMyProfileId();

    try {
      await Supabase.instance.client.from('follows').insert({
        'follower_id': myProfileId,
        'following_id': targetProfileId,
        'status': 'pending',
      });
    } catch (e) {
      throw NetworkException('Failed to send follow request: $e');
    }
  }

  Future<void> cancelOrUnfollow(String targetProfileId) async {
    final myProfileId = await _ref.read(profileLookupProvider).getMyProfileId();

    try {
      await Supabase.instance.client.from('follows')
          .delete()
          .eq('follower_id', myProfileId)
          .eq('following_id', targetProfileId);
    } catch (e) {
      throw NetworkException('Failed to unfollow: $e');
    }
  }

  Future<void> acceptFollowRequest(String followId) async {
    try {
      await Supabase.instance.client
          .from('follows')
          .update({'status': 'accepted'})
          .eq('id', followId);
    } catch (e) {
      throw NetworkException('Failed to accept request: $e');
    }
  }

  Future<void> rejectFollowRequest(String followId) async {
    try {
      await Supabase.instance.client
          .from('follows')
          .delete()
          .eq('id', followId);
    } catch (e) {
      throw NetworkException('Failed to reject request: $e');
    }
  }
}
