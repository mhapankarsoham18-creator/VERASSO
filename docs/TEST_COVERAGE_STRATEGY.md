# Phase 9: Test Coverage Improvement Strategy

**Goal:** Increase LCOV coverage from 13.95% → ≥50% in 2 weeks  
**Timeline:** Weeks 1-2 of Phase 9  
**Owner:** QA + Backend Team  

---

## Coverage Gap Analysis

### Current State (Baseline: 13.95%)

**Estimated coverage by module:**
| Module | Est. Current | Target | Gap | Tests Needed |
|--------|--------------|--------|-----|--------------|
| `lib/core/security/` | 30% | 85% | 55% | 20+ |
| `lib/core/storage/` | 45% | 85% | 40% | 12+ |
| `lib/core/monitoring/` | 25% | 80% | 55% | 15+ |
| `lib/features/messaging/` | 35% | 65% | 30% | 18+ |
| `lib/features/learning/` | 40% | 65% | 25% | 14+ |
| `lib/features/finance/` | 50% | 75% | 25% | 10+ |
| `lib/services/` | 40% | 70% | 30% | 16+ |
| Mock repositories | 20% | 80% | 60% | 24+ |
| **TOTAL** | **13.95%** | **≥50%** | **36.05%** | **~150+ tests** |

---

## Week 1: CRITICAL PATH (Security-First Testing)

Focus on HIGH-RISK modules that, if failed, could cause security incidents:

### Priority 1: `lib/core/security/encryption_service.dart` (30% → 85%)

**Current Coverage:** ~30% (missing 20+ test cases)  
**Effort:** 8 hours  
**Priority:** 🔴 CRITICAL - Used for E2E encryption

#### Tests to Add

```dart
// test/core/security/encryption_service_critical_test.dart

group('Encryption Service - Critical Security Tests', () {
  
  // Key Management (8 tests)
  test('key generation produces unique keys', () { /* ... */ });
  test('key export includes modulus and exponent', () { /* ... */ });
  test('public key upload succeeds', () { /* ... */ });
  test('private key never exposed in logs', () { /* ... */ });
  test('key rotation updates active key', () { /* ... */ });
  test('old keys remain valid during rotation', () { /* ... */ });
  test('decryption with wrong key fails', () { /* ... */ });
  test('key deletion prevents future decryption', () { /* ... */ });
  
  // Message Encryption (6 tests)
  test('encryptMessage produces deterministic output', () { /* ... */ });
  test('encrypted message differs from plaintext', () { /* ... */ });
  test('encryption handles null/empty input', () { /* ... */ });
  test('batch encryption of multiple messages succeeds', () { /* ... */ });
  test('group message encrypted for all recipients', () { /* ... */ });
  test('encryption fails gracefully on key unavailable', () { /* ... */ });
  
  // Decryption Security (4 tests)
  test('decryptMessage requires valid signature', () { /* ... */ });
  test('tampered message fails integrity check', () { /* ... */ });
  test('replay attack is detected (timestamp check)', () { /* ... */ });
  test('decryption timeout prevents resource DoS', () { /* ... */ });
  
  // Key Storage (2 tests)
  test('keys persisted encrypted in Hive', () { /* ... */ });
  test('keys cannot be read via Hive inspection', () { /* ... */ });
});
```

**Expected outcome:** Encryption module at 85% coverage, no untested code paths for key mgmt.

---

### Priority 2: `lib/core/storage/encrypted_hive_storage.dart` (45% → 85%)

**Current Coverage:** ~45% (missing 12+ test cases)  
**Effort:** 6 hours  
**Priority:** 🔴 CRITICAL - Local data security

#### Tests to Add

```dart
// test/core/storage/encrypted_hive_storage_critical_test.dart

group('Encrypted Hive Storage - Critical Tests', () {
  
  // Encryption at Rest (6 tests)
  test('all data persisted as encrypted bytes', () { /* ... */ });
  test('encryption key derived from user ID', () { /* ... */ });
  test('reading encrypted data auto-decrypts', () { /* ... */ });
  test('decryption timeout handled', () { /* ... */ });
  test('corrupted encrypted data fails gracefully', () { /* ... */ });
  test('encryption key rotation updates records', () { /* ... */ });
  
  // CRUD with Encryption (4 tests)
  test('write encrypts before persistence', () { /* ... */ });
  test('update re-encrypts data', () { /* ... */ });
  test('delete securely removes decrypted copy', () { /* ... */ });
  test('read returns decrypted value', () { /* ... */ });
  
  // Data Isolation (2 tests)
  test('user A cannot read user B encrypted data', () { /* ... */ });
  test('encryption prevents plaintext leakage', () { /* ... */ });
});
```

**Expected outcome:** At-rest encryption fully tested, no plaintext data leaks.

---

### Priority 3: `lib/core/security/rate_limit_service.dart`

**Current Coverage:** ~40% (missing 10+ test cases)  
**Effort:** 5 hours  
**Priority:** 🔴 CRITICAL - Brute force protection

#### Tests to Add

```dart
group('Rate Limit Service - Security Tests', () {
  
  // Brute Force Protection (5 tests)
  test('password reset limited to 3/hour', () { /* ... */ });
  test('login limited after 5 failed attempts', () { /* ... */ });
  test('lockout duration 15 minutes', () { /* ... */ });
  test('ip-based rate limiting prevents enumeration', () { /* ... */ });
  test('rate limit bypass attempts fail', () { /* ... */ });
  
  // Rate Limit Window Behavior (3 tests)
  test('rate limit window resets correctly', () { /* ... */ });
  test('concurrent requests counted fairly', () { /* ... */ });
  test('distributed attack across IPs still limited', () { /* ... */ });
  
  // Edge Cases (2 tests)
  test('clock skew handling', () { /* ... */ });
  test('database slow response doesn\'t skip checks', () { /* ... */ });
});
```

**Expected outcome:** Rate limiting fully validated for production.

---

## Week 2: IMPORTANT PATH (Feature-Critical Testing)

### Priority 4: `lib/features/messaging/` (35% → 65%)

**Modules:**
- `message_service.dart`
- `message_repository.dart`
- `encryption_service.dart` (already done)

**Tests to Add:**

```dart
// test/features/messaging/messaging_critical_test.dart

group('Messaging - Coverage Critical Tests', () {
  
  // Message Send/Receive (6 tests)
  test('send message creates DB record', () { /* ... */ });
  test('receive message decrypts content', () { /* ... */ });
  test('bulk send to group encrypts for each', () { /* ... */ });
  test('message timestamps maintained', () { /* ... */ });
  test('corrupted message handling', () { /* ... */ });
  test('delivery webhook updates status', () { /* ... */ });
  
  // Read Receipts (4 tests)
  test('mark as read updates timestamp', () { /* ... */ });
  test('read receipt sent to sender', () { /* ... */ });
  test('unread count correct', () { /* ... */ });
  test('bulk mark as read atomic', () { /* ... */ });
  
  // Search & Archive (3 tests)
  test('search messages in conversation', () { /* ... */ });
  test('archive conversation hides from list', () { /* ... */ });
  test('unarchive restores to active list', () { /* ... */ });
  
  // Error Cases (3 tests)
  test('send to non-existent user fails', () { /* ... */ });
  test('network error retries message', () { /* ... */ });
  test('permission check prevents unauthorized read', () { /* ... */ });
});
```

**Expected outcome:** Messaging at 65%+, critical flows fully tested.

---

### Priority 5: `lib/features/learning/` (40% → 65%)

**Modules:**
- `course_service.dart`
- `lesson_service.dart`
- `quiz_service.dart`

**Tests to Add:**

```dart
group('Learning - Coverage Expansion', () {
  
  // Course Management (5 tests)
  test('fetch course with lessons', () { /* ... */ });
  test('update course progress', () { /* ... */ });
  test('complete course marks as done', () { /* ... */ });
  test('archived course not visible', () { /* ... */ });
  test('course recommendation logic', () { /* ... */ });
  
  // Lesson Delivery (4 tests)
  test('lesson content loads correctly', () { /* ... */ });
  test('high-fidelity simulation initializes', () { /* ... */ });
  test('progress saved between sessions', () { /* ... */ });
  test('next lesson navigation works', () { /* ... */ });
  
  // Quiz Mechanics (4 tests)
  test('quiz attempts tracked per user', () { /* ... */ });
  test('score calculated correctly', () { /* ... */ });
  test('passing quiz unlocks next lesson', () { /* ... */ });
  test('quiz submission validates answers', () { /* ... */ });
  
  // Analytics (2 tests)
  test('time spent tracked per lesson', () { /* ... */ });
  test('dropout point identified', () { /* ... */ });
});
```

**Expected outcome:** Learning paths fully exercised in tests.

---

### Priority 6: Mock Repository Tests (20% → 80%)

**Modules:**
- `mock_post_repository.dart`
- `mock_message_repository.dart`
- `mock_user_repository.dart`

These are critical for integration tests. They need 80%+ coverage:

```dart
// test/mocks/mock_repositories_coverage_test.dart

group('Mock Repository Coverage', () {
  
  // Mock Post Repo (8 tests)
  test('createPost stores and returns with ID', () { /* ... */ });
  test('getPost retrieves by ID', () { /* ... */ });
  test('updatePost modifies existing', () { /* ... */ });
  test('deletePost removes', () { /* ... */ });
  test('getFeed paginates correctly', () { /* ... */ });
  test('createPost increments counter', () { /* ... */ });
  test('error simulation for network fail', () { /* ... */ });
  test('mock persistence survives scope', () { /* ... */ });
  
  // Mock Message Repo (7 tests)
  test('sendMessage encrypts and stores', () { /* ... */ });
  test('getMessages decrypts on retrieve', () { /* ... */ });
  test('getUnreadCount correct', () { /* ... */ });
  test('markAsRead updates timestamp', () { /* ... */ });
  test('delete conversation removes all', () { /* ... */ });
  test('parallel sends handled', () { /* ... */ });
  test('mock failure injection works', () { /* ... */ });
  
  // Mock User Repo (6 tests)
  test('createUser stores profile', () { /* ... */ });
  test('getUser retrieves by ID', () { /* ... */ });
  test('updateUser modifies', () { /* ... */ });
  test('follow user creates relation', () { /* ... */ });
  test('search users by name', () { /* ... */ });
  test('mock data consistency', () { /* ... */ });
});
```

**Expected outcome:** All mocks at 80%+, no untested paths.

---

## Week 2: SECONDARY PATH (Service-Level Testing)

### Priority 7: `lib/core/monitoring/app_logger.dart`

**Tests to add:** 8 test cases  
**Target:** 30% → 80%

```dart
group('App Logger Coverage', () {
  test('log formats message correctly', () { /* ... */ });
  test('error level logs stack trace', () { /* ... */ });
  test('info level has no stack trace', () { /* ... */ });
  test('warning level has alert flag', () { /* ... */ });
  test('logs include timestamp', () { /* ... */ });
  test('log file rotation after limit', () { /* ... */ });
  test('failed log doesn\'t crash app', () { /* ... */ });
  test('sensitive data redacted from logs', () { /* ... */ });
});
```

---

## Execution Schedule (2-Week Sprint)

### Week 1 (Feb 18-24)

**Monday-Tuesday:** Critical path (security modules)
- [ ] Encryption service tests (8h) - 20 tests
- [ ] Storage encryption tests (6h) - 12 tests
- [ ] Rate limiting tests (5h) - 10 tests
- **Total:** 19 hours, 42 tests

**Wednesday-Friday:** Audit setup + first batch integration
- [ ] Integrate tests into CI
- [ ] Run coverage report
- [ ] Contract security firm
- [ ] First coverage measurement

### Week 2 (Feb 25-Mar 3)

**Daily:** Important path (feature modules)
- [ ] Messaging tests (6h) - 16 tests (Mon-Tue)
- [ ] Learning tests (6h) - 15 tests (Tue-Wed)
- [ ] Mock repository tests (8h) - 24 tests (Wed-Thu)
- [ ] Logger tests (2h) - 8 tests (Thu)
- [ ] Integration + cleanup (4h) (Fri)
- **Total:** 26 hours, 63 tests

**Total for Weeks 1-2:** 45 hours, 105+ new tests

---

## Coverage Measurement

### How to Check Coverage

```bash
# 1. Run tests with coverage
cd d:\Games\VERASSO
flutter test --coverage

# 2. Generate HTML report
genhtml coverage/lcov.info -o coverage/report

# 3. Open in browser
open coverage/report/index.html

# 4. Check specific module
grep "^SF:" coverage/lcov.info | head -20
```

### CI/CD Integration

Add to `.github/workflows/test.yml`:

```yaml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Check coverage >= 50%
  run: |
    python3 scripts/check_coverage.py coverage/lcov.info 50
```

---

## Success Criteria

| Criteria | Target | Week 1 | Week 2 | Week 3 |
|----------|--------|--------|--------|--------|
| **LCOV Coverage %** | ≥50% | 20% | 40% | ✅ 50%+ |
| **Tests Added** | 150+ | 42 | 63 | ✅ |
| **Security Tests** | 50+ | 42 | 25+ | ✅ |
| **Feature Tests** | 100+ | — | 63 | ✅ |
| **CI Gate** | Active | — | — | ✅ |
| **Security Audit** | Contracted | ✅ | In-progress | Complete |

---

## Common Pitfalls to Avoid

1. **Too many low-level tests** - focus on critical paths first, then helpers
2. **Mock overuse** - balance mocks with real integration tests
3. **Skipping error cases** - 50% of tests should be error/edge cases
4. **No cleanup** - use `tearDown()` to prevent test interference
5. **Global state** - reset state between tests

---

## Tools & Resources

**Coverage Analysis:**
- `genhtml` - visualization
- Online LCOV explorers - per-file breakdown

**Test Generation Help:**
- Copilot/ChatGPT - generate test templates
- Stack Overflow - common test patterns

**Debugging:**
- Run single test: `flutter test test/file_test.dart -k "test name"`
- Verbose output: `flutter test --verbose`
- Pause on error: `flutter test --pdb` (if supported)

---

## Document Control

**Last Updated:** February 18, 2026  
**Owner:** QA + Backend Team  
**Key Dependency:** Phase 8 tests (50+ test files already created)
