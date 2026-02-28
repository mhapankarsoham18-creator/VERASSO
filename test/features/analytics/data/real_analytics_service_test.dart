import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/analytics/data/analytics_service.dart';

import '../../../mocks.dart';

void main() {
  late AnalyticsService service;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    service = AnalyticsService(client: mockSupabase);
  });

  group('AnalyticsService Unit Tests', () {
    test('getContentStats fetches from content_stats table', () async {
      final mockResponse = {
        'content_id': 'c1',
        'content_type': 'post',
        'views_count': 100,
        'likes_count': 10,
        'comments_count': 5,
        'shares_count': 2,
        'engagement_rate': 0.17,
      };

      final mockQuery =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockQuery.setResponse([mockResponse]);

      final mockQueryBuilder =
          MockSupabaseQueryBuilder(stubs: {'select': mockQuery});
      mockSupabase.fromStub = (table) {
        if (table == 'content_stats') return mockQueryBuilder;
        return MockSupabaseQueryBuilder();
      };

      final result = await service.getContentStats('c1');

      expect(result, isNotNull);
      expect(result!.contentId, 'c1');
      expect(result.viewsCount, 100);
    });

    test('getTopContent fetches ordered list', () async {
      final mockResponse = [
        {
          'content_id': 'c1',
          'content_type': 'post',
          'views_count': 100,
          'engagement_rate': 0.5
        },
        {
          'content_id': 'c2',
          'content_type': 'post',
          'views_count': 50,
          'engagement_rate': 0.3
        },
      ];

      final mockQuery =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockQuery.setResponse(mockResponse);

      final mockQueryBuilder =
          MockSupabaseQueryBuilder(stubs: {'select': mockQuery});
      mockSupabase.fromStub = (table) => mockQueryBuilder;

      final results = await service.getTopContent('u1', limit: 2);

      expect(results.length, 2);
      expect(results[0].contentId, 'c1');
      expect(results[1].contentId, 'c2');
    });

    test('getUserStats fetches user stats', () async {
      final mockResponse = {
        'user_id': 'u1',
        'posts_count': 10,
        'engagement_score': 8.5,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final mockQuery =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockQuery.setResponse([mockResponse]);

      final mockQueryBuilder =
          MockSupabaseQueryBuilder(stubs: {'select': mockQuery});
      mockSupabase.fromStub = (table) {
        if (table == 'user_stats') return mockQueryBuilder;
        return MockSupabaseQueryBuilder();
      };

      final result = await service.getUserStats('u1');

      expect(result, isNotNull);
      expect(result!.userId, 'u1');
      expect(result.postsCount, 10);
    });

    test('refreshUserStats calls RPC', () async {
      mockSupabase.setRpcResponse('update_user_stats', null);

      // We can't easily spy on the RPC call with the current mock setup
      // without modifying MockSupabaseClient to track calls,
      // but we can ensure it doesn't throw.
      await service.refreshUserStats('u1');
    });

    test('trackEvent inserts into analytics_events', () async {
      final mockAuth = MockGoTrueClient();
      mockAuth.setCurrentUser(TestSupabaseUser(id: 'u1'));
      mockSupabase.setAuth(mockAuth);

      final mockQuery = MockPostgrestFilterBuilder<dynamic>();
      final mockQueryBuilder =
          MockSupabaseQueryBuilder(stubs: {'insert': mockQuery});
      mockSupabase.fromStub = (table) {
        if (table == 'analytics_events') return mockQueryBuilder;
        return MockSupabaseQueryBuilder();
      };

      await service.trackEvent('test_event', {'prop': 1});
    });

    test('updateContentStats inserts new record if not exists', () async {
      // 1. Check existing (returns null)
      final mockSelectQuery =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockSelectQuery.setResponse([]); // No existing record

      // 2. Insert
      final mockInsertQuery = MockPostgrestFilterBuilder<dynamic>();

      final mockQueryBuilder = MockSupabaseQueryBuilder(stubs: {
        'select': mockSelectQuery,
        'insert': mockInsertQuery,
      });

      mockSupabase.fromStub = (table) => mockQueryBuilder;

      await service.updateContentStats(
        contentId: 'c1',
        contentType: 'post',
        viewsDelta: 1,
      );
    });

    test('getUserEngagement calls RPC', () async {
      final mockResponse = [
        {
          'date': '2026-02-15T00:00:00.000Z',
          'posts': 3,
          'likes': 12,
          'comments': 5,
        }
      ];
      mockSupabase.setRpcResponse('get_user_engagement', mockResponse);

      final results = await service.getUserEngagement('u1');

      expect(results.length, 1);
      expect(results.first.posts, 3);
    });
  });
}
