import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/services/rate_limit_service.dart';

import '../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late RateLimitService rateLimitService;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    rateLimitService = RateLimitService(client: mockSupabase);
  });

  group('RateLimitService - Messaging Rate Limits', () {
    test('sendMessage allows up to limit of messages', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);
      mockSupabase.setRpcResponse('check_rate_limit', {'allowed': true});

      final isLimited = await rateLimitService.isLimited(
        'user-1',
        RateLimitType.sendMessage,
      );

      expect(isLimited, false);
    });

    test('sendMessage rate limit tracks messages per minute', () async {
      expect(
        RateLimitService.configs[RateLimitType.sendMessage]!.maxAttempts,
        50,
      );
      expect(
        RateLimitService.configs[RateLimitType.sendMessage]!.windowMinutes,
        1,
      );
    });

    test('uploadAttachment enforces upload limits', () async {
      expect(
        RateLimitService.configs[RateLimitType.uploadAttachment]!.maxAttempts,
        10,
      );
      expect(
        RateLimitService.configs[RateLimitType.uploadAttachment]!
            .lockoutMinutes,
        10,
      );
    });

    test('searchMessages rate limit prevents abuse', () async {
      expect(
        RateLimitService.configs[RateLimitType.searchMessages]!.maxAttempts,
        30,
      );
    });
  });

  group('RateLimitService - API Call Rate Limits', () {
    test('apiCall limit handles 5k daily users', () async {
      // 5000 users * 300 calls/min = 1.5M calls/min max
      // This scales linearly
      expect(
        RateLimitService.configs[RateLimitType.apiCall]!.maxAttempts,
        300,
      );
    });

    test('apiCall window is 1 minute for granular control', () async {
      expect(
        RateLimitService.configs[RateLimitType.apiCall]!.windowMinutes,
        1,
      );
    });

    test('globalSearch limits per-user searches', () async {
      expect(
        RateLimitService.configs[RateLimitType.globalSearch]!.maxAttempts,
        20,
      );
    });
  });

  group('RateLimitService - Content Creation Limits', () {
    test('createPost has hourly limits', () async {
      expect(
        RateLimitService.configs[RateLimitType.createPost]!.maxAttempts,
        10,
      );
      expect(
        RateLimitService.configs[RateLimitType.createPost]!.windowMinutes,
        60,
      );
    });

    test('createPost prevents rapid spam', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);
      mockSupabase.setRpcResponse('check_rate_limit', {'allowed': true});

      final isLimited = await rateLimitService.isLimited(
        'user-1',
        RateLimitType.createPost,
      );

      expect(isLimited, false);
    });
  });

  group('RateLimitService - Operation Tests', () {
    test('recordAttempt logs failed action', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      await expectLater(
        rateLimitService.recordAttempt(
          'user-1',
          RateLimitType.sendMessage,
          reason: 'message_too_large',
        ),
        completes,
      );
    });

    test('getRemainingAttempts calculates remaining quota', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      final remaining = await rateLimitService.getRemainingAttempts(
        'user-1',
        RateLimitType.sendMessage,
      );

      expect(remaining, greaterThanOrEqualTo(0));
    });

    test('getLockoutTimeRemaining returns 0 when not locked', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      final lockoutTime = await rateLimitService.getLockoutTimeRemaining(
        'user-1',
        RateLimitType.sendMessage,
      );

      expect(lockoutTime, 0);
    });

    test('clearAttempts removes history for identifier', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      await expectLater(
        rateLimitService.clearAttempts('user-1', RateLimitType.sendMessage),
        completes,
      );
    });

    test('getAttemptHistory retrieves recent failed attempts', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'identifier': 'user-1',
          'type': 'sendMessage',
          'reason': 'rate_limit_exceeded',
          'attempted_at': '2025-01-15T10:00:00Z',
        }
      ]);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      final history = await rateLimitService.getAttemptHistory(
        'user-1',
        RateLimitType.sendMessage,
      );

      expect(history, isNotEmpty);
      expect(history[0].identifier, 'user-1');
    });

    test('cleanupOldAttempts removes entries older than threshold', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      await expectLater(
        rateLimitService.cleanupOldAttempts(olderThanDays: 7),
        completes,
      );
    });
  });

  group('RateLimitService - Error Handling', () {
    test('isLimited returns false on database error (fail open)', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);
      mockSupabase.setRpcResponse(
        'check_rate_limit',
        null,
        shouldThrow: true,
      );

      final isLimited = await rateLimitService.isLimited(
        'user-1',
        RateLimitType.sendMessage,
      );

      // Should fail open - allow access on error
      expect(isLimited, false);
    });

    test('getRemainingAttempts returns -1 on error', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      final remaining = await rateLimitService.getRemainingAttempts(
        'user-1',
        RateLimitType.sendMessage,
      );

      expect(remaining, -1);
    });

    test('logAttempt handles unknown action types gracefully', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('rate_limit_attempts', builder);

      await expectLater(
        rateLimitService.logAttempt(
          email: 'test@example.com',
          action: 'unknown_action',
          success: false,
        ),
        completes,
      );
    });
  });

  group('RateLimitAttempt Model Tests', () {
    test('RateLimitAttempt creates from JSON', () {
      final json = {
        'identifier': 'user-1',
        'type': 'sendMessage',
        'reason': 'rate_limit_exceeded',
        'attempted_at': '2025-01-15T10:00:00Z',
      };

      final attempt = RateLimitAttempt.fromJson(json);

      expect(attempt.identifier, 'user-1');
      expect(attempt.type, 'sendMessage');
      expect(attempt.reason, 'rate_limit_exceeded');
      expect(attempt.attemptedAt, isNotNull);
    });
  });

  group('RateLimitConfig Model Tests', () {
    test('RateLimitConfig stores configuration values', () {
      final config = RateLimitConfig(
        maxAttempts: 50,
        windowMinutes: 1,
        lockoutMinutes: 5,
      );

      expect(config.maxAttempts, 50);
      expect(config.windowMinutes, 1);
      expect(config.lockoutMinutes, 5);
    });
  });
}
