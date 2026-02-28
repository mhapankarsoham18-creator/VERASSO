import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/monitoring/app_logger.dart';
import '../../core/monitoring/sentry_service.dart';
import '../../core/services/supabase_service.dart';

/// Provider for the [ModerationService].
final moderationServiceProvider = Provider<ModerationService>((ref) {
  return ModerationService();
});

/// Service responsible for community moderation actions like reporting and muting.
class ModerationService {
  final SupabaseClient _client;

  /// Creates a [ModerationService] with an optional [client].
  ModerationService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Returns a list of user IDs that the specified [userId] has muted.
  Future<List<String>> getMutedUserIds(String userId) async {
    try {
      final response = await _client
          .from('mutes')
          .select('muted_user_id')
          .eq('user_id', userId);

      return (response as List)
          .map((e) => e['muted_user_id'] as String)
          .toList();
    } catch (e, stack) {
      AppLogger.error('Failed to fetch muted users', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Mutes a user, preventing their content from appearing in the current user's feed.
  Future<void> muteUser({
    required String userId,
    required String mutedUserId,
  }) async {
    try {
      await _client.from('mutes').insert({
        'user_id': userId,
        'muted_user_id': mutedUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
      AppLogger.info('User muted: $mutedUserId by $userId');
    } catch (e, stack) {
      AppLogger.error('Failed to mute user', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Reports a piece of content (post or comment).
  Future<void> reportContent({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    try {
      await _client.from('reports').insert({
        'reporter_id': reporterId,
        'target_id': targetId,
        'target_type': targetType,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
      AppLogger.info('Content reported: $targetId ($targetType)');
    } catch (e, stack) {
      AppLogger.error('Failed to report content', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Unmutes a previously muted user.
  Future<void> unmuteUser({
    required String userId,
    required String mutedUserId,
  }) async {
    try {
      await _client
          .from('mutes')
          .delete()
          .eq('user_id', userId)
          .eq('muted_user_id', mutedUserId);
      AppLogger.info('User unmuted: $mutedUserId');
    } catch (e, stack) {
      AppLogger.error('Failed to unmute user', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }
}
