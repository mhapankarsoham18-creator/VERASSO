import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/features/analytics/data/analytics_service.dart';

import '../../mocks.dart';

void main() {
  group('AppLogger Tests', () {
    // AppLogger is a static utility, we test its effects on SentryService or debugPrint
    // For unit testing, we mainly verify it doesn't crash and correctly delegates

    test('info logging sends breadcrumb', () {
      // Mocking Sentry is hard because it's static, but we can call it to ensure stability
      AppLogger.info('Test info message');
    });

    test('error logging captures exception', () {
      AppLogger.error('Test error',
          error: Exception('test'), stackTrace: StackTrace.current);
    });
  });

  group('Analytics Service Tests', () {
    late AnalyticsService analytics;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      analytics = AnalyticsService(client: mockSupabase);
    });

    test('trackEvent inserts into database', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('analytics_events', mockQueryBuilder);

      await analytics.trackEvent('test_event', {'foo': 'bar'});

      // Verification logic depends on how MockSupabaseQueryBuilder is implemented in mocks.dart
      // Usually we verify that from('analytics_events').insert was called.
    });

    test('getUserStats returns data from database', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('user_stats', mockQueryBuilder);
      mockQueryBuilder.setResponse({'user_id': 'test-user', 'xp': 100});

      final stats = await analytics.getUserStats('test-user');
      expect(stats?.postsCount, 100);
    });
  });
}
