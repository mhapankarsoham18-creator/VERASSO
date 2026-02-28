import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../../core/services/supabase_service.dart';

/// Provider for the [RelationshipRepository].
final relationshipRepositoryProvider = Provider<RelationshipRepository>((ref) {
  return RelationshipRepository();
});

/// Repository for managing user relationships (friends, blocks, requests).
class RelationshipRepository {
  final SupabaseClient _client;

  /// Creates a [RelationshipRepository] instance.
  RelationshipRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Accepts a pending friend request from [requesterId].
  Future<void> acceptFriendRequest(String requesterId,
      {bool allowsPersonal = false}) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    try {
      await _client
          .from('relationships')
          .update({
            'status': 'friends',
            'target_allows_personal': allowsPersonal,
          })
          .eq('user_id', requesterId)
          .eq('target_id', myId);
    } catch (e) {
      AppLogger.info('Accept friend request error: $e');
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Blocks a user, preventing them from interacting with the current user.
  Future<void> blockUser(String targetId) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    try {
      await _client.from('relationships').upsert(
          {'user_id': myId, 'target_id': targetId, 'status': 'blocked'});
    } catch (e) {
      AppLogger.info('Block user error: $e');
      throw Exception('Failed to block user: $e');
    }
  }

  /// Retrieves the list of friends for the current user.
  Future<List<Map<String, dynamic>>> getFriends() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return [];

    try {
      final response = await _client
          .from('relationships')
          .select('*, profiles:target_id(*)')
          .or('user_id.eq.$myId,target_id.eq.$myId')
          .eq('status', 'friends');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.info('Get friends error: $e');
      return [];
    }
  }

  /// Retrieves incoming pending friend requests.
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return [];

    try {
      final response = await _client
          .from('relationships')
          .select('*, profiles:user_id(*)')
          .eq('target_id', myId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.info('Get pending requests error: $e');
      return [];
    }
  }

  // Check status: 'none', 'pending_sent', 'pending_received', 'friends', 'blocked_by_me', 'blocked_by_them'
  /// Gets the current relationship status between the active user and [otherUserId].
  Future<String> getRelationshipStatus(String otherUserId) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return 'none';
    if (myId == otherUserId) return 'self';

    try {
      final response = await _client.rpc('get_relationship_status',
          params: {'current_user_id': myId, 'other_user_id': otherUserId});
      return response as String;
    } catch (e) {
      AppLogger.info('Get relationship status error: $e');
      return 'none';
    }
  }

  /// Sends a friend request to the specified [targetId].
  Future<void> sendFriendRequest(String targetId,
      {bool allowsPersonal = false}) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    try {
      await _client.from('relationships').insert({
        'user_id': myId,
        'target_id': targetId,
        'status': 'pending',
        'user_allows_personal': allowsPersonal,
      });
    } catch (e) {
      AppLogger.info('Send friend request error: $e');
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Removes a friendship or cancels a pending request.
  Future<void> unfriendOrCancel(String otherUserId) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    try {
      await _client.from('relationships').delete().or(
          'and(user_id.eq.$myId,target_id.eq.$otherUserId),and(user_id.eq.$otherUserId,target_id.eq.$myId)');
    } catch (e) {
      AppLogger.info('Unfriend error: $e');
      throw Exception('Failed to unfriend: $e');
    }
  }

  /// Updates whether [otherUserId] can see personal posts/logs.
  Future<void> updatePersonalVisibility(
      String otherUserId, bool allowsPersonal) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    try {
      // Check if I am user_id
      await _client
          .from('relationships')
          .update({'user_allows_personal': allowsPersonal})
          .eq('user_id', myId)
          .eq('target_id', otherUserId);

      // Check if I am target_id
      await _client
          .from('relationships')
          .update({'target_allows_personal': allowsPersonal})
          .eq('user_id', otherUserId)
          .eq('target_id', myId);
    } catch (e) {
      AppLogger.info('Update personal visibility error: $e');
      throw Exception('Failed to update visibility: $e');
    }
  }
}
