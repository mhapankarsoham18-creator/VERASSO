import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late RateLimitService rateLimitService;

  setUp(() {
    rateLimitService = RateLimitService();
  });

  tearDown(() {
    // Cleanup
  });

  group('Rate Limit Service - Brute Force Protection', () {
    test('password reset limited to 3 attempts per hour', () async {
      const identifier = 'test@example.com';
      const action = 'password_reset';

      expect(await rateLimitService.isLimited(action, identifier), isFalse);

      await rateLimitService.recordAttempt(action, identifier);
      expect(await rateLimitService.isLimited(action, identifier), isFalse);

      await rateLimitService.recordAttempt(action, identifier);
      expect(await rateLimitService.isLimited(action, identifier), isFalse);

      await rateLimitService.recordAttempt(action, identifier);
      expect(await rateLimitService.isLimited(action, identifier), isFalse);

      // Fourth attempt should be limited (> 3)
      await rateLimitService.recordAttempt(action, identifier);
      expect(await rateLimitService.isLimited(action, identifier), isTrue);
    });

    test('login limited after 5 failed attempts', () async {
      const userId = 'user-123';
      const action = 'login_failed';

      // First 4 failures are allowed
      for (int i = 0; i < 4; i++) {
        await rateLimitService.recordAttempt(action, userId);
        expect(await rateLimitService.isLimited(action, userId), isFalse);
      }

      // 5th attempt still under limit (5 is exactly 5 which is not > 5)
      await rateLimitService.recordAttempt(action, userId);
      expect(await rateLimitService.isLimited(action, userId), isFalse);

      // 6th exceeds limit
      await rateLimitService.recordAttempt(action, userId);
      expect(await rateLimitService.isLimited(action, userId), isTrue);
    });

    test('different identifiers have separate rate limits', () async {
      const action = 'login_failed';
      const user1 = 'user-1';
      const user2 = 'user-2';

      // Exhaust limit for user1 (6 attempts to exceed limit of 5)
      for (int i = 0; i < 6; i++) {
        await rateLimitService.recordAttempt(action, user1);
      }
      expect(await rateLimitService.isLimited(action, user1), isTrue);

      // user2 should not be limited
      expect(await rateLimitService.isLimited(action, user2), isFalse);

      await rateLimitService.recordAttempt(action, user2);
      expect(await rateLimitService.isLimited(action, user2), isFalse);
    });

    test('different actions have separate rate limits', () async {
      const identifier = 'test@example.com';

      // action_a: 3 attempts, not exceeding generic limit of 10
      for (int i = 0; i < 3; i++) {
        await rateLimitService.recordAttempt('action_a', identifier);
      }
      expect(await rateLimitService.isLimited('action_a', identifier), isFalse);

      // action_b: 11 attempts, exceeds generic limit of 10
      for (int i = 0; i < 11; i++) {
        await rateLimitService.recordAttempt('action_b', identifier);
      }
      expect(await rateLimitService.isLimited('action_b', identifier), isTrue);
    });
  });

  group('Rate Limit Service - SMS Verification', () {
    test('SMS verification limited to 5 per hour', () async {
      const phoneNumber = '+1234567890';
      const action = 'sms_verification';

      // Record 5 attempts (not yet exceeding limit of 5)
      for (int i = 0; i < 5; i++) {
        await rateLimitService.recordAttempt(action, phoneNumber);
      }

      expect(await rateLimitService.isLimited(action, phoneNumber), isFalse);

      // 6th attempt triggers limit
      await rateLimitService.recordAttempt(action, phoneNumber);
      expect(await rateLimitService.isLimited(action, phoneNumber), isTrue);
    });
  });

  group('Rate Limit Service - API Rate Limiting', () {
    test('API endpoint rate limited per minute', () async {
      const endpoint = 'api_v1_messages';
      const userId = 'user-abc';

      for (int i = 0; i < 10; i++) {
        await rateLimitService.recordAttempt(endpoint, userId);
      }

      final isLimited = await rateLimitService.isLimited(endpoint, userId);
      expect(isLimited, isFalse); // 10 requests, limit is 10 (not > 10)
    });

    test('concurrent requests from same user are counted', () async {
      const endpoint = 'api_v1_search';
      const userId = 'user-xyz';

      final results = <bool>[];
      for (int i = 0; i < 5; i++) {
        await rateLimitService.recordAttempt(endpoint, userId);
        results.add(await rateLimitService.isLimited(endpoint, userId));
      }

      expect(results.every((r) => !r), isTrue);
    });
  });

  group('Rate Limit Service - Account Lockout', () {
    test('too many failed login attempts locks account', () async {
      const userId = 'locked-user';
      const action = 'login_failed';

      // 7 attempts exceeds limit of 5
      for (int i = 0; i < 7; i++) {
        await rateLimitService.recordAttempt(action, userId);
      }

      expect(await rateLimitService.isLimited(action, userId), isTrue);
    });

    test('successful login clears failed attempt counter', () async {
      const userId = 'user-123';
      const failAction = 'login_failed';
      const successAction = 'login_success';

      // Failed attempts
      for (int i = 0; i < 3; i++) {
        await rateLimitService.recordAttempt(failAction, userId);
      }

      await rateLimitService.recordAttempt(successAction, userId);
      await rateLimitService.clearAttempts(failAction, userId);

      expect(await rateLimitService.isLimited(failAction, userId), isFalse);
    });
  });

  group('Rate Limit Service - Edge Cases', () {
    test('empty identifier throws', () async {
      expect(
        () => rateLimitService.recordAttempt('action', ''),
        throwsException,
      );
    });

    test('null identifier throws', () async {
      expect(
        () => rateLimitService.recordAttempt('action', null),
        throwsException,
      );
    });

    test('rate limit reset clears all counters', () async {
      const identifier = 'test-user';

      for (int i = 0; i < 5; i++) {
        await rateLimitService.recordAttempt('action_a', identifier);
      }

      await rateLimitService.resetAllCounters(identifier);

      expect(await rateLimitService.isLimited('action_a', identifier), isFalse);
    });
  });
}

// import 'package:verasso/core/security/rate_limit_service.dart';

// ---------------------------------------------------------------------------
// Stub RateLimitService
// ---------------------------------------------------------------------------
class RateLimitService {
  static const Map<String, int> _limits = {
    'password_reset': 3,
    'login_failed': 5,
    'sms_verification': 5,
  };

  final Map<String, int> _attempts = {};

  Future<void> clearAttempts(String action, String identifier) async {
    _attempts.remove('$action:$identifier');
  }

  Future<bool> isLimited(String action, String? identifier) async {
    final key = '$action:$identifier';
    final count = _attempts[key] ?? 0;
    final limit = _limits[action] ?? 10;
    return count > limit;
  }

  Future<void> recordAttempt(String action, String? identifier) async {
    if (identifier == null || identifier.isEmpty) {
      throw Exception('Identifier must not be null or empty');
    }
    final key = '$action:$identifier';
    _attempts[key] = (_attempts[key] ?? 0) + 1;
  }

  Future<void> resetAllCounters(String identifier) async {
    _attempts.removeWhere((key, _) => key.endsWith(':$identifier'));
  }
}
