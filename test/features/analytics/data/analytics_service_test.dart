import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/features/analytics/data/analytics_service.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AnalyticsService service;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockClient = MockSupabaseClient(auth: mockAuth);
    service = AnalyticsService(client: mockClient);

    when(mockAuth.currentUser).thenReturn(
      User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'aud',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  });

  group('AnalyticsService - Event Tracking', () {
    test('trackEvent inserts into analytics_events table', () async {
      final properties = {'screen': 'home'};

      await service.trackEvent('page_view', properties);

      expect(mockClient.lastInsertTable, 'analytics_events');
    });

    test('trackEvent does nothing if user is not logged in', () async {
      when(mockAuth.currentUser).thenReturn(null);

      await service.trackEvent('page_view');

      expect(mockClient.lastInsertTable, isNull);
    });
  });

  group('AnalyticsService - Statistics', () {
    test('getUserStats fetches from user_stats table', () async {
      final mockStats = {
        'user_id': 'user-123',
        'posts_count': 5,
        'followers_count': 10,
        'following_count': 20,
        'likes_received': 100,
        'comments_received': 50,
        'engagement_score': 8.5,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder = MockPostgrestFilterBuilder<Map<String, dynamic>?>();
      filterBuilder.setResponse(mockStats);
      mockClient.setQueryBuilder('user_stats', queryBuilder);

      final result = await service.getUserStats('user-123');

      expect(result, isNotNull);
      expect(result!.postsCount, 5);
      expect(result.likesReceived, 100);
    });

    test('getUserStats calls update_user_stats RPC if no stats exist',
        () async {
      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder = MockPostgrestFilterBuilder<Map<String, dynamic>?>();

      // First call returns null, second call (after RPC) returns stats
      filterBuilder.setResponse(null);
      mockClient.setQueryBuilder('user_stats', queryBuilder);

      // Note: AnalyticsService.getUserStats has a recursive retry.
      // We'd need a more complex mock to handle the second call returning data.
      // But we can at least verify the RPC was called.

      try {
        await service.getUserStats('user-123');
      } catch (_) {}

      expect(mockClient.lastRpcName, 'update_user_stats');
    });

    test('getTopContent fetches from content_stats table ordered by engagement',
        () async {
      final mockContent = [
        {'content_id': 'c1', 'content_type': 'post', 'engagement_rate': 0.9},
        {'content_id': 'c2', 'content_type': 'post', 'engagement_rate': 0.8},
      ];

      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      filterBuilder.setResponse(mockContent);
      mockClient.setQueryBuilder('content_stats', queryBuilder);

      final result = await service.getTopContent('user-123', limit: 2);

      expect(result.length, 2);
      expect(result.first.contentId, 'c1');
    });

    test('getUserEngagement calls get_user_engagement RPC', () async {
      final mockEngagement = [
        {'date': '2026-02-27', 'posts': 1, 'likes': 5, 'comments': 2}
      ];

      mockClient.setRpcResponse('get_user_engagement', mockEngagement);

      final result = await service.getUserEngagement('user-123');

      expect(result, isNotEmpty);
      expect(result.first.posts, 1);
      expect(mockClient.lastRpcName, 'get_user_engagement');
    });
  });

  group('AnalyticsService - Content Performance', () {
    test('updateContentStats increments counts in content_stats table',
        () async {
      final existingStats = {
        'content_id': 'c1',
        'content_type': 'post',
        'views_count': 10,
        'likes_count': 2,
        'comments_count': 1,
        'shares_count': 0,
      };

      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder = MockPostgrestFilterBuilder<Map<String, dynamic>?>();
      filterBuilder.setResponse(existingStats);
      mockClient.setQueryBuilder('content_stats', queryBuilder);

      await service.updateContentStats(
        contentId: 'c1',
        contentType: 'post',
        viewsDelta: 1,
      );

      expect(mockClient.lastUpdateTable, 'content_stats');
    });
  });
}
