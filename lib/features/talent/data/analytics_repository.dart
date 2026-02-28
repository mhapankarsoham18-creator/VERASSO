import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

/// Provider for the [AnalyticsRepository] instance.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

/// Repository for tracking and retrieving analytics data.
class AnalyticsRepository {
  final SupabaseClient _client;

  /// Creates an [AnalyticsRepository].
  AnalyticsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Fetches aggregated stats (views, impressions) for a specific target.
  Future<Map<String, int>> getStats(String targetId) async {
    try {
      final viewsResponse = await _client
          .from('analytics_events')
          .select('id')
          .eq('event_name', 'view')
          .eq('properties->>target_id', targetId)
          .count(CountOption.exact);

      final impressionsResponse = await _client
          .from('analytics_events')
          .select('id')
          .eq('event_name', 'impression')
          .eq('properties->>target_id', targetId)
          .count(CountOption.exact);

      return {
        'views': viewsResponse.count,
        'impressions': impressionsResponse.count
      };
    } catch (e) {
      return {'views': 0, 'impressions': 0};
    }
  }

  /// Tracks an analytics event.
  ///
  /// [eventType] is the name of the event (e.g., 'view', 'click').
  /// [targetType] is the type of object being interacted with.
  /// [targetId] is the ID of the object.
  Future<void> trackEvent({
    required String eventType,
    required String targetType,
    required String targetId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('analytics_events').insert({
        'user_id': userId,
        'event_name': eventType,
        'properties': {'target_type': targetType, 'target_id': targetId},
      });
    } catch (e) {
      // Analytics failures should not crash the app
    }
  }
}
