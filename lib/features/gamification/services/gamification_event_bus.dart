import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

// ── Event Types ──────────────────────────────────────────────

/// Map of action → configuration.
const _actionConfigs = <GamificationAction, GamificationActionConfig>{
  GamificationAction.postCreated: GamificationActionConfig(
    baseXP: 15,
    cooldown: Duration(minutes: 5),
    dbActionType: 'post_created',
  ),
  GamificationAction.commentWritten: GamificationActionConfig(
    baseXP: 5,
    cooldown: Duration(minutes: 1),
    dbActionType: 'comment_written',
  ),
  GamificationAction.likeGiven: GamificationActionConfig(
    baseXP: 2,
    cooldown: Duration(seconds: 10),
    dbActionType: 'like_given',
  ),
  GamificationAction.messageSent: GamificationActionConfig(
    baseXP: 3,
    cooldown: Duration(seconds: 30),
    dbActionType: 'message_sent',
  ),
  GamificationAction.lessonCompleted: GamificationActionConfig(
    baseXP: 25,
    cooldown: Duration.zero,
    dbActionType: 'lesson_completed',
  ),
  GamificationAction.challengeSolved: GamificationActionConfig(
    baseXP: 50,
    cooldown: Duration.zero,
    dbActionType: 'challenge_solved',
  ),
  GamificationAction.quizPassed: GamificationActionConfig(
    baseXP: 20,
    cooldown: Duration.zero,
    dbActionType: 'quiz_passed',
  ),
  GamificationAction.courseEnrolled: GamificationActionConfig(
    baseXP: 10,
    cooldown: Duration.zero,
    dbActionType: 'course_enrolled',
  ),
  GamificationAction.streakMaintained: GamificationActionConfig(
    baseXP: 10,
    cooldown: Duration(hours: 20),
    dbActionType: 'streak_maintained',
  ),
  GamificationAction.talentListed: GamificationActionConfig(
    baseXP: 20,
    cooldown: Duration(hours: 1),
    dbActionType: 'talent_listed',
  ),
  GamificationAction.friendMade: GamificationActionConfig(
    baseXP: 5,
    cooldown: Duration.zero,
    dbActionType: 'friend_made',
  ),
  GamificationAction.profileCompleted: GamificationActionConfig(
    baseXP: 50,
    cooldown: Duration(days: 365),
    dbActionType: 'profile_completed',
  ),
  GamificationAction.storyPosted: GamificationActionConfig(
    baseXP: 10,
    cooldown: Duration(minutes: 15),
    dbActionType: 'story_posted',
  ),
  GamificationAction.arProjectCreated: GamificationActionConfig(
    baseXP: 30,
    cooldown: Duration.zero,
    dbActionType: 'ar_project_created',
  ),
  GamificationAction.bugReported: GamificationActionConfig(
    baseXP: 15,
    cooldown: Duration(hours: 1),
    dbActionType: 'bug_reported',
  ),
  GamificationAction.doubtAnswered: GamificationActionConfig(
    baseXP: 10,
    cooldown: Duration(minutes: 2),
    dbActionType: 'doubt_answered',
  ),
};

/// Provider for the singleton [GamificationEventBus].
final gamificationEventBusProvider = Provider<GamificationEventBus>((ref) {
  final bus = GamificationEventBus(Supabase.instance.client);
  ref.onDispose(bus.dispose);
  return bus;
});

/// All gamification-triggering actions in the app.
enum GamificationAction {
  /// User created a post.
  postCreated,

  /// User wrote a comment.
  commentWritten,

  /// User liked something.
  likeGiven,

  /// User sent a message.
  messageSent,

  /// User completed a lesson.
  lessonCompleted,

  /// User solved a coding challenge.
  challengeSolved,

  /// User passed a quiz.
  quizPassed,

  /// User enrolled in a course.
  courseEnrolled,

  /// User maintained a daily streak.
  streakMaintained,

  /// User listed a talent.
  talentListed,

  /// User made a new friend/follower.
  friendMade,

  /// User completed their profile.
  profileCompleted,

  /// User posted a story.
  storyPosted,

  /// User created an AR project.
  arProjectCreated,

  /// User reported a bug.
  bugReported,

  /// User answered a doubt.
  doubtAnswered,
}

/// Configuration for each gamification action.
class GamificationActionConfig {
  /// Base XP awarded for this action.
  final int baseXP;

  /// Time required before this action can yield XP again.
  final Duration cooldown;

  /// Action type identifier stored in the database.
  final String dbActionType;

  /// Creates a configuration for a gamification action.
  const GamificationActionConfig({
    required this.baseXP,
    required this.cooldown,
    required this.dbActionType,
  });
}

// ── Provider ─────────────────────────────────────────────────

/// A gamification event carrying the action, user, and optional metadata.
class GamificationEvent {
  /// The action that occurred.
  final GamificationAction action;

  /// The user who performed the action.
  final String userId;

  /// Optional metadata (e.g. post ID, quiz score).
  final Map<String, dynamic> metadata;

  /// Creates a [GamificationEvent].
  const GamificationEvent({
    required this.action,
    required this.userId,
    this.metadata = const {},
  });

  /// Gets the config for this action.
  GamificationActionConfig get config => _actionConfigs[action]!;

  /// Key for cooldown tracking: userId + action.
  String get cooldownKey => '${userId}_${action.name}';
}

// ── Event Bus ────────────────────────────────────────────────

/// Central event bus that intercepts user actions and awards XP,
/// checks achievements, updates quests, and logs actions.
class GamificationEventBus {
  final SupabaseClient _supabase;
  final _controller = StreamController<GamificationEvent>.broadcast();
  final Map<String, DateTime> _cooldowns = {};
  StreamSubscription? _subscription;

  /// Creates the event bus and starts listening.
  GamificationEventBus(this._supabase) {
    _subscription = _controller.stream.listen(_processEvent);
  }

  /// Stream of events for external listeners (e.g. UI toasts).
  Stream<GamificationEvent> get stream => _controller.stream;

  /// Dispose the bus.
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }

  /// Emit a gamification event. Silently drops if on cooldown.
  void emit(GamificationEvent event) {
    if (_isOnCooldown(event)) {
      AppLogger.debug(
        'Gamification: ${event.action.name} on cooldown for ${event.userId}',
      );
      return;
    }
    _cooldowns[event.cooldownKey] = DateTime.now();
    _controller.add(event);
  }

  /// Convenience: emit by action + userId.
  void track(
    GamificationAction action,
    String userId, {
    Map<String, dynamic> metadata = const {},
  }) {
    emit(GamificationEvent(action: action, userId: userId, metadata: metadata));
  }

  Future<void> _awardXP(String userId, String actionType, int xp) async {
    try {
      // Use the new secure RPC to record the activity and update user_stats
      await _supabase.rpc(
        'record_activity_v2',
        params: {
          'p_activity_name': actionType,
          'p_metadata': {'awarded_by_client': true, 'xp': xp},
        },
      );
    } catch (e) {
      AppLogger.error('Failed to securely award XP for $userId', error: e);
    }

    // Trigger achievement check
    try {
      await _supabase.rpc(
        'check_user_achievements',
        params: {'p_user_id': userId},
      );
    } catch (_) {
      // RPC may be missing
    }
  }

  // ── Internal Processing ──────────────────────────────────

  bool _isOnCooldown(GamificationEvent event) {
    final cooldown = event.config.cooldown;
    if (cooldown == Duration.zero) return false;
    final last = _cooldowns[event.cooldownKey];
    if (last == null) return false;
    return DateTime.now().difference(last) < cooldown;
  }

  Future<void> _logAction(
    GamificationEvent event,
    int xp,
    double multiplier,
  ) async {
    await _supabase.from('gamification_action_log').insert({
      'user_id': event.userId,
      'action_type': event.config.dbActionType,
      'xp_awarded': xp,
      'multiplier': multiplier,
      'metadata': event.metadata,
    });
  }

  Future<void> _processEvent(GamificationEvent event) async {
    try {
      final config = event.config;

      // 1. Server-side anti-cheat validation
      final validation = await _validateAction(event);
      if (validation['allowed'] != true) {
        AppLogger.debug(
          'Gamification: ${config.dbActionType} blocked by anti-cheat: ${validation['reason']}',
        );
        return;
      }

      final multiplier = (validation['multiplier'] as num?)?.toDouble() ?? 1.0;
      final xp = (config.baseXP * multiplier).round();

      // 2. Log the action (anti-cheat record)
      await _logAction(event, xp, multiplier);

      // 3. Award XP
      await _awardXP(event.userId, config.dbActionType, xp);

      // 4. Update quest progress
      await _updateQuestProgress(event.userId, config.dbActionType);

      // 5. Update guild XP if user is in a guild
      await _updateGuildXP(event.userId, xp);

      AppLogger.info(
        'Gamification: +${xp}XP (${multiplier}x) for ${config.dbActionType}',
      );
    } catch (e) {
      AppLogger.error('Gamification event processing failed', error: e);
    }
  }

  Future<void> _updateGuildXP(String userId, int xp) async {
    try {
      final membership = await _supabase
          .from('guild_members')
          .select('guild_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (membership != null) {
        final guildId = membership['guild_id'] as String;

        // Use the unified increment RPC
        await _supabase.rpc(
          'increment_guild_xp',
          params: {
            'p_guild_id': guildId,
            'p_user_id': userId,
            'p_xp': xp,
          },
        );
      }
    } catch (e) {
      // Guild XP is non-critical, silently fail
      AppLogger.debug('Guild XP update skipped or failed: $e');
    }
  }

  Future<void> _updateQuestProgress(String userId, String actionType) async {
    try {
      // Find matching active quests
      final quests = await _supabase
          .from('quests')
          .select('id, quest_type, target_count')
          .eq('action_type', actionType)
          .eq('is_active', true);

      final now = DateTime.now();
      for (final quest in quests as List) {
        final questId = quest['id'] as String;
        final questType = quest['quest_type'] as String;
        final target = quest['target_count'] as int;

        // Calculate reset_at based on quest type
        final resetAt = questType == 'daily'
            ? DateTime(now.year, now.month, now.day).toIso8601String()
            : DateTime(
                now.year,
                now.month,
                now.day - now.weekday + 1,
              ).toIso8601String();

        // Upsert progress
        final existing = await _supabase
            .from('user_quest_progress')
            .select()
            .eq('user_id', userId)
            .eq('quest_id', questId)
            .eq('reset_at', resetAt)
            .maybeSingle();

        if (existing != null) {
          if (existing['is_completed'] == true) continue; // already done
          final newCount = (existing['current_count'] as int) + 1;
          await _supabase.from('user_quest_progress').update({
            'current_count': newCount,
            'is_completed': newCount >= target,
            'completed_at': newCount >= target ? now.toIso8601String() : null,
          }).eq('id', existing['id']);

          // Award quest XP on completion
          if (newCount >= target) {
            await _awardXP(
              userId,
              'quest_completed',
              quest['xp_reward'] as int? ?? 0,
            );
          }
        } else {
          await _supabase.from('user_quest_progress').insert({
            'user_id': userId,
            'quest_id': questId,
            'current_count': 1,
            'is_completed': 1 >= target,
            'completed_at': 1 >= target ? now.toIso8601String() : null,
            'reset_at': resetAt,
          });
        }
      }
    } catch (e) {
      AppLogger.error('Quest progress update failed', error: e);
    }
  }

  Future<Map<String, dynamic>> _validateAction(GamificationEvent event) async {
    try {
      final response = await _supabase.rpc(
        'validate_gamification_action',
        params: {
          'p_user_id': event.userId,
          'p_action_type': event.config.dbActionType,
          'p_cooldown_seconds': event.config.cooldown.inSeconds,
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      // If validation fails, allow by default (graceful degradation)
      return {'allowed': true, 'multiplier': 1.0};
    }
  }
}
