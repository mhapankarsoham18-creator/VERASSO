import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Model for a Reward associated with an event.
class EventReward {
  /// Unique ID of the reward.
  final String id;

  /// Optional associated achievement ID.
  final String? achievementId;

  /// XP bonus awarded upon completion.
  final int xpBonus;

  /// ID for exclusive digital item/badge.
  final String? exclusiveItemId;

  /// Criteria required to earn this reward.
  final Map<String, dynamic> requirementCriteria;

  /// Creates an [EventReward].
  EventReward({
    required this.id,
    this.achievementId,
    required this.xpBonus,
    this.exclusiveItemId,
    required this.requirementCriteria,
  });

  /// Creates an [EventReward] from JSON.
  factory EventReward.fromJson(Map<String, dynamic> json) {
    return EventReward(
      id: json['id'],
      achievementId: json['achievement_id'],
      xpBonus: json['xp_bonus'] ?? 0,
      exclusiveItemId: json['exclusive_item_id'],
      requirementCriteria: json['requirement_criteria'] ?? {},
    );
  }
}

/// Service for managing seasonal events and time-limited challenges.
class SeasonalChallengeService {
  final SupabaseClient _client;

  /// Creates a [SeasonalChallengeService].
  SeasonalChallengeService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Checks if a user has completed requirements for a specific seasonal event.
  ///
  /// This calls the `check_seasonal_event_completion` Supabase RPC which
  /// automatically awards rewards if metrics are met.
  Future<void> checkEventCompletion(String eventId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.rpc('check_seasonal_event_completion', params: {
        'p_user_id': userId,
        'p_event_id': eventId,
      });
    } catch (e, stack) {
      AppLogger.error('Failed to check seasonal event completion', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException(
          'Failed to check seasonal event completion', null, e);
    }
  }

  /// Fetches currently active seasonal events along with their associated rewards.
  ///
  /// Uses the `get_active_seasonal_events_with_rewards` RPC for optimized data fetching.
  Future<List<SeasonalEvent>> getActiveEvents() async {
    try {
      final response =
          await _client.rpc('get_active_seasonal_events_with_rewards');

      return (response as List).map((e) => SeasonalEvent.fromJson(e)).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to fetch active seasonal events', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw DatabaseException(
          'Failed to fetch active seasonal events', null, e);
    }
  }
}

/// Model for a Seasonal Event.
class SeasonalEvent {
  /// Unique ID of the event.
  final String id;

  /// Display title.
  final String title;

  /// Optional description.
  final String? description;

  /// When the event starts.
  final DateTime startAt;

  /// When the event ends.
  final DateTime endAt;

  /// Additional configuration.
  final Map<String, dynamic> metadata;

  /// List of rewards associated with this event.
  final List<EventReward> rewards;

  /// Creates a [SeasonalEvent].
  SeasonalEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.metadata,
    this.rewards = const [],
  });

  /// Creates a [SeasonalEvent] from JSON.
  factory SeasonalEvent.fromJson(Map<String, dynamic> json) {
    return SeasonalEvent(
      id: json['event_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      startAt:
          DateTime.parse(json['start_at'] ?? DateTime.now().toIso8601String()),
      endAt: DateTime.parse(json['end_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] ?? {},
      rewards: json['rewards'] != null
          ? (json['rewards'] as List)
              .map((r) => EventReward.fromJson(r))
              .toList()
          : [],
    );
  }
}
