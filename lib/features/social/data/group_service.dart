import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/supabase_service.dart';
import '../../messaging/services/encryption_service.dart';
import '../models/group_models.dart';

/// Provider for the [GroupService].
final groupServiceProvider = Provider<GroupService>((ref) {
  final encryption = ref.watch(encryptionServiceProvider);
  return GroupService(encryptionService: encryption);
});

/// Service for managing collaborative groups (Circles), including E2EE messaging.
class GroupService {
  final SupabaseClient _client;
  final EncryptionService _encryptionService;

  /// Creates a [GroupService] instance.
  GroupService(
      {SupabaseClient? client, required EncryptionService encryptionService})
      : _client = client ?? SupabaseService.client,
        _encryptionService = encryptionService;

  /// Creates a new group with the given [name] and [description].
  Future<Group> createGroup({
    required String name,
    String? description,
    bool isPrivate = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Not authenticated');

      final response = await _client
          .from('groups')
          .insert({
            'name': name,
            'description': description,
            'owner_id': userId,
            'is_private': isPrivate,
          })
          .select()
          .single();

      return Group.fromJson(response);
    } catch (e, stack) {
      AppLogger.error('Create group error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to create group', null, e);
    }
  }

  /// Retrieves all members belonging to a specific group.
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _client
          .from('group_members')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      return (response as List).map((e) {
        final profile = e['profiles'] as Map<String, dynamic>?;
        return GroupMember.fromJson({
          ...e,
          'full_name': profile?['full_name'],
          'avatar_url': profile?['avatar_url'],
        });
      }).toList();
    } catch (e, stack) {
      AppLogger.error('Get group members error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to get group members', null, e);
    }
  }

  /// Streams real-time messages for a group, handling E2EE decryption on-the-fly.
  Stream<List<GroupMessage>> getGroupMessages(String groupId) {
    final myId = _client.auth.currentUser?.id;
    return _client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          final messages = <GroupMessage>[];
          for (final row in data) {
            String content = row['content'] ?? '[Encrypted]';

            // If encrypted_content exists, try to decrypt
            if (row['encrypted_content'] != null) {
              try {
                // To decrypt, we need the key for this user.
                // In a real stream, we might want to join group_message_keys.
                // For now, we fetch it if not present in row.
                final keyResponse = await _client
                    .from('group_message_keys')
                    .select('encrypted_key')
                    .eq('message_id', row['id'])
                    .eq('user_id', myId!)
                    .maybeSingle();

                if (keyResponse != null) {
                  final messageWithKey = {
                    ...row,
                    'my_encrypted_key': keyResponse['encrypted_key'],
                  };
                  content = await _encryptionService
                      .decryptMessage(messageWithKey, isGroup: true);
                } else if (row['sender_id'] == myId) {
                  content = await _encryptionService.decryptMessage(row,
                      isGroup: true);
                }
              } catch (e, stack) {
                AppLogger.error('Decryption failed for group msg ${row['id']}',
                    error: e);
                SentryService.captureException(e, stackTrace: stack);
              }
            }

            messages.add(GroupMessage.fromJson({
              ...row,
              'content': content,
            }));
          }
          return messages;
        });
  }

  /// Fetches all available groups (public ones plus the user's private memberships).
  Future<List<Group>> getGroups() async {
    try {
      final response = await _client
          .from('groups')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((e) => Group.fromJson(e)).toList();
    } catch (e, stack) {
      AppLogger.error('Get groups error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to get groups', null, e);
    }
  }

  /// Checks if the current user is a member of the specified group.
  Future<GroupMember?> getUserMembership(String groupId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? GroupMember.fromJson(response) : null;
    } catch (e, stack) {
      AppLogger.error('Get user membership error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }

  /// Adds the current user to a group as a regular member.
  Future<void> joinGroup(String groupId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Not authenticated');

      await _client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e, stack) {
      AppLogger.error('Join group error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to join group', null, e);
    }
  }

  /// Removes the current user from the specified group.
  Future<void> leaveGroup(String groupId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Not authenticated');

      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Leave group error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to leave group', null, e);
    }
  }

  /// Removes a specific member from a group (requires moderator/owner permissions).
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Remove member error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to remove member', null, e);
    }
  }

  /// Sends an end-to-end encrypted message to all group members.
  Future<void> sendGroupMessage(String groupId, String content) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Not authenticated');

      // 1. Get all member IDs to encrypt for them
      final members = await getGroupMembers(groupId);
      final receiverIds =
          members.map((m) => m.userId).where((id) => id != userId).toList();

      // 2. Encrypt
      final encryptedData =
          await _encryptionService.encryptGroupMessage(content, receiverIds);

      // 3. Insert Message
      final messageResponse = await _client
          .from('group_messages')
          .insert({
            'group_id': groupId,
            'sender_id': userId,
            'encrypted_content': encryptedData['content'],
            'iv_text': encryptedData['iv'],
            'key_for_sender': encryptedData['key_sender'],
            'media_type': 'text',
          })
          .select('id')
          .single();

      final messageId = messageResponse['id'];

      // 4. Insert Keys for members
      final keysToInsert =
          (encryptedData['keys_per_user'] as Map<String, String>)
              .entries
              .map((e) => {
                    'message_id': messageId,
                    'user_id': e.key,
                    'encrypted_key': e.value,
                  })
              .toList();

      if (keysToInsert.isNotEmpty) {
        await _client.from('group_message_keys').insert(keysToInsert);
      }
    } catch (e, stack) {
      AppLogger.error('Send group message error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to send encrypted message', null, e);
    }
  }

  /// Updates a member's role (requires moderator/owner permissions).
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) async {
    try {
      await _client
          .from('group_members')
          .update({'role': role.name})
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Update member role error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException('Failed to update member role', null, e);
    }
  }
}
