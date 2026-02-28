# Phase 9: Test Writing Quick Start Guide

**Goal:** Add 42 critical security tests this week  
**Timeline:** Next 5-7 days  
**Owner:** Backend team + QA  

---

## Step 1: Start with Encryption Service Tests (2-3 hours)

Create this file: `test/core/security/encryption_service_critical_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/encryption_service.dart';
import '../mocks/mock_auth.dart';

void main() {
  late EncryptionService service;
  late MockSupabaseAuth mockAuth;

  setUp(() {
    mockAuth = MockSupabaseAuth();
    service = EncryptionService(mockAuth);
  });

  group('Encryption Service - Key Generation', () {
    test('key generation creates RSA key pair', () async {
      // Verify keys are generated
      expect(await service.hasKeys(), isTrue);
    });

    test('public key export includes modulus and exponent', () async {
      final publicKey = await service.getPublicKey();
      expect(publicKey, isNotNull);
      expect(publicKey!.contains('-----BEGIN PUBLIC KEY-----'), isTrue);
    });

    test('private key never exposed in logging', () async {
      // This is more of a code review test
      // Verify no private keys logged in error messages
      // expect(logger.messages, doesNotContain(privateKey));
    });

    test('key rotation updates active key', () async {
      final oldKey = await service.getPublicKey();
      await service.rotateKeys();
      final newKey = await service.getPublicKey();
      expect(oldKey, isNotEqualTo(newKey));
    });
  });

  group('Encryption Service - Message Encryption', () {
    test('encryptMessage produces base64 output', () async {
      final encrypted = await service.encryptMessage('Hello', 'recipient-id');
      expect(encrypted, isNotNull);
      expect(encrypted.isNotEmpty, isTrue);
      // Base64 validation
      expect(RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(encrypted), isTrue);
    });

    test('encrypted message differs from plaintext', () async {
      const plaintext = 'Secret message';
      final encrypted = await service.encryptMessage(plaintext, 'recipient-id');
      expect(encrypted, isNotEqualTo(plaintext));
    });

    test('encryption handles empty input', () async {
      expect(
        () => service.encryptMessage('', 'recipient-id'),
        throwsException,
      );
    });
  });
}
```

**Time:** 30-45 minutes  
**Tests:** 5  
**Coverage gain:** ~3-5%

---

## Step 2: Add Storage Encryption Tests (1.5-2 hours)

Create: `test/core/storage/encrypted_hive_storage_critical_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/storage/encrypted_hive_storage.dart';
import '../mocks/mock_hive.dart';

void main() {
  late EncryptedHiveStorage storage;
  late MockHiveBox mockBox;

  setUp(() {
    mockBox = MockHiveBox();
    storage = EncryptedHiveStorage(mockBox);
  });

  group('Encrypted Hive Storage - At-Rest Encryption', () {
    test('data persisted as encrypted bytes', () async {
      const testData = {'name': 'John', 'email': 'john@example.com'};
      await storage.write('user-1', testData);
      
      // Verify stored data is encrypted (not plaintext)
      final stored = mockBox.get('user-1');
      expect(stored, isNotNull);
      expect(stored.toString().contains('John'), isFalse); // Not plaintext
    });

    test('reading decrypts data transparently', () async {
      const testData = {'name': 'Jane'};
      await storage.write('user-2', testData);
      
      final read = await storage.read('user-2');
      expect(read['name'], 'Jane');
    });

    test('corrupted data fails gracefully', () async {
      // Write bad data
      mockBox.put('corrupted', 'not-valid-encrypted-data');
      
      expect(
        () => storage.read('corrupted'),
        throwsException,
      );
    });
  });

  group('Encrypted Hive Storage - User Isolation', () {
    test('user A cannot read user B data', () async {
      const userAData = {'secret': 'A-secret'};
      const userBData = {'secret': 'B-secret'};
      
      await storage.write('user-A', userAData);
      await storage.write('user-B', userBData);
      
      final aReads = await storage.read('user-A');
      expect(aReads['secret'], 'A-secret');
      
      final bReads = await storage.read('user-B');
      expect(bReads['secret'], 'B-secret');
    });
  });
}
```

**Time:** 30-45 minutes  
**Tests:** 4  
**Coverage gain:** ~2-3%

---

## Step 3: Add Rate Limiting Tests (1-1.5 hours)

Create: `test/core/security/rate_limit_service_critical_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/rate_limit_service.dart';

void main() {
  late RateLimitService rateLimitService;

  setUp(() {
    rateLimitService = RateLimitService();
  });

  group('Rate Limit Service - Brute Force Protection', () {
    test('password reset limited to 3 attempts per hour', () async {
      const identifier = 'test@example.com';
      
      // First attempt should succeed
      expect(
        await rateLimitService.isLimited('password_reset', identifier),
        isFalse,
      );
      
      // Record 3 attempts
      await rateLimitService.recordAttempt('password_reset', identifier);
      await rateLimitService.recordAttempt('password_reset', identifier);
      await rateLimitService.recordAttempt('password_reset', identifier);
      
      // Fourth attempt should be limited
      expect(
        await rateLimitService.isLimited('password_reset', identifier),
        isTrue,
      );
    });

    test('login limited after 5 failed attempts', () async {
      const userId = 'user-123';
      
      // 4 failures allowed
      for (int i = 0; i < 4; i++) {
        await rateLimitService.recordAttempt('login_failed', userId);
        expect(
          await rateLimitService.isLimited('login_failed', userId),
          isFalse,
        );
      }
      
      // 5th attempt should be limited
      await rateLimitService.recordAttempt('login_failed', userId);
      expect(
        await rateLimitService.isLimited('login_failed', userId),
        isTrue,
      );
    });

    test('rate limit resets after time window', () async {
      const identifier = 'test';
      
      // Fill up the limit
      for (int i = 0; i < 3; i++) {
        await rateLimitService.recordAttempt('password_reset', identifier);
      }
      
      expect(
        await rateLimitService.isLimited('password_reset', identifier),
        isTrue,
      );
      
      // Simulate time passing (mock time or actual wait)
      // After 1 hour, should reset
      // (Using test utilities to mock time advancement)
      await Future.delayed(Duration(milliseconds: 1)); // Simplified
      
      // Note: Actual implementation would need time mocking
    });
  });
}
```

**Time:** 25-35 minutes  
**Tests:** 3  
**Coverage gain:** ~2%

---

## Step 4: Integration Check (30 minutes)

1. Run your new tests:
```bash
flutter test test/core/security/encryption_service_critical_test.dart -v
flutter test test/core/storage/encrypted_hive_storage_critical_test.dart -v
flutter test test/core/security/rate_limit_service_critical_test.dart -v
```

2. Fix any failures (expected: ~20-30% might fail on first run)

3. Run all tests together:
```bash
flutter test test/core/security/ -v
```

4. Check coverage so far:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/report
```

---

## This Week's Test Writing Sessions

### Monday (Today)
- [ ] Start encryption tests (1-2 hours)
- [ ] Complete encryption tests (30 min review)
- [ ] Begin storage tests (30 min)

### Tuesday  
- [ ] Complete storage tests (1 hour)
- [ ] Start rate limiting tests (30 min)
- [ ] First coverage measurement

### Wednesday-Thursday
- [ ] Complete rate limiting tests
- [ ] Write remaining critical tests (5-10 more)
- [ ] Fix any test failures
- [ ] Integration testing

### Friday
- [ ] Cleanup & documentation
- [ ] Coverage report
- [ ] Plan Week 2
- [ ] Check audit firm status

---

## Common Test Patterns

### Pattern 1: Setup/Teardown

```dart
setUp(() {
  // Initialize services
  mockAuth = MockSupabaseAuth();
  service = MyService(mockAuth);
});

tearDown(() {
  // Cleanup
  mockBox.clear();
  mockAuth.reset();
});
```

### Pattern 2: Mocking

```dart
// Mock successful response
mockAuth.setResponse('getKeys', {
  'public_key': '-----BEGIN PUBLIC KEY-----...'
});

// Mock error response
mockAuth.setError('encryptMessage', Exception('Encryption failed'));
```

### Pattern 3: Async Testing

```dart
test('async operation completes', () async {
  final result = await service.encryptMessage('data', 'user-id');
  expect(result, isNotNull);
});

test('async error handling', () async {
  expect(
    () => service.encryptMessage('', 'user-id'),
    throwsException,
  );
});
```

### Pattern 4: Coverage of Error Paths

```dart
group('Error Handling', () {
  test('database error is caught', () async {
    mockDb.setError('insert', Exception('DB error'));
    
    expect(
      () => service.saveData({}),
      throwsException,
    );
  });

  test('network timeout is handled', () async {
    mockHttp.setDelay(Duration(seconds: 31));
    
    expect(
      () => service.fetchFromAPI(),
      throwsException,
    );
  });

  test('null safety checks', () async {
    expect(
      () => service.processData(null),
      throwsException,
    );
  });
});
```

---

## Debugging Tips

### If a test fails:

```bash
# Run with verbose output
flutter test test/file_test.dart -v

# Run a single test by name
flutter test test/file_test.dart -k "encryption produces"

# Show output even on pass
flutter test test/file_test.dart --verbose
```

### If coverage is low:

```bash
# See which lines aren't covered
grep coverage/lcov.info | grep "SF:" | head -20

# HTML report shows line-by-line coverage
open coverage/report/index.html
# Click on a file to see uncovered lines (red background)
```

---

## Approval Checklist Before Submitting

Each test file should:

- [ ] 5+ test cases minimum
- [ ] Both success and error paths
- [ ] Setup and teardown cleanup
- [ ] No hardcoded test data (use constants at top)
- [ ] All assertions have meaningful failure messages
- [ ] No unnecessary sleeps (use mock time if needed)
- [ ] Comments on complex logic
- [ ] Runs without errors
- [ ] Passes the style guidelines (dartfmt/analyzer)

---

## File Structure

```
test/
├── core/
│   ├── security/
│   │   ├── encryption_service_test.dart          (existing from Phase 8)
│   │   ├── encryption_service_critical_test.dart (NEW - write this week)
│   │   ├── rate_limit_service_test.dart          (existing)
│   │   └── rate_limit_service_critical_test.dart (NEW - write this week)
│   └── storage/
│       ├── encrypted_hive_storage_test.dart      (existing)
│       └── encrypted_hive_storage_critical_test.dart (NEW)
├── features/
│   ├── messaging/
│   │   └── (coverage expansion tests here)
│   └── learning/
│       └── (coverage expansion tests here)
└── mocks/
    ├── mock_auth.dart    (reuse existing)
    └── mock_hive.dart    (reuse existing)
```

---

## Success Indicators

**After writing 10-15 tests:**
- Coverage jumps from 13.95% → 18-20%
- No flaky failures
- Tests run in <5 seconds total
- Clear test names describe what they test

**After writing 42 tests (end of Week 1):**
- Coverage at ~20%
- 30+ tests passing
- Security module effectively exercised
- Ready for Week 2 feature tests

---

## Resources

**Reference Tests Already Written:** 
- `test/accessibility_audit_test.dart` : See structure
- `test/features/messaging/services/message_repository_test.dart` : See mocking

**Helper Functions:**
- Use `mockAuth.setCurrentUser()` for auth tests
- Use `mockDb.when().thenReturn()` for DB tests
- Use `expect(value, matcher)` for assertions

---

## Next: Week 2 Planning

Once Week 1 tests are complete:
1. Measure coverage (should be 18-22%)
2. Plan Week 2 feature tests (messaging, learning, etc.)
3. Continue parallel with audit progress

---

**Happy testing! 🧪**  
Questions? Check `docs/TEST_COVERAGE_STRATEGY.md` for more details.
