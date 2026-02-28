import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/password_hashing_service.dart';

void main() {
  group('Password Hashing Service Tests', () {
    test('Hash password should generate unique hashes for same password',
        () async {
      const password = 'TestPassword123!';

      final hash1 = await PasswordHashingService.hashPassword(password);
      final hash2 = await PasswordHashingService.hashPassword(password);

      // Hashes should be different due to unique salts
      expect(hash1, isNot(equals(hash2)));

      // But both should be verifiable
      expect(
          await PasswordHashingService.verifyPassword(password, hash1), true);
      expect(
          await PasswordHashingService.verifyPassword(password, hash2), true);
    });

    test('Verify password should return true for correct password', () async {
      const password = 'SecurePass456!';

      final hash = await PasswordHashingService.hashPassword(password);
      final isValid =
          await PasswordHashingService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Verify password should return false for incorrect password',
        () async {
      const password = 'CorrectPassword789!';
      const wrongPassword = 'WrongPassword000!';

      final hash = await PasswordHashingService.hashPassword(password);
      final isValid =
          await PasswordHashingService.verifyPassword(wrongPassword, hash);

      expect(isValid, false);
    });

    test('Hash should be different with random padding', () async {
      const password = 'TestPass!123';

      final hash1 = await PasswordHashingService.hashPassword(password);
      final hash2 = await PasswordHashingService.hashPassword(password);

      // Even same password should produce different hashes
      expect(hash1, isNot(equals(hash2)));
    });

    test('Hash should be long enough (bcrypt standard)', () async {
      const password = 'MyPassword123!';

      final hash = await PasswordHashingService.hashPassword(password);

      // Bcrypt hashes are 60 characters
      expect(hash.length, 60);
    });

    test('Hash should start with bcrypt identifier', () async {
      const password = 'ValidPass456!';

      final hash = await PasswordHashingService.hashPassword(password);

      // Bcrypt hashes start with $2a$, $2b$, or $2y$
      expect(hash.startsWith(RegExp(r'\$2[aby]\$')), true);
    });

    test('Password validation should enforce minimum length', () {
      const shortPassword = 'Pass1!';

      final (isValid, message) =
          PasswordHashingService.validatePasswordStrength(shortPassword);

      expect(isValid, false);
      expect(message, contains('at least 8 characters'));
    });

    test('Password validation should require uppercase', () {
      const noUpperPassword = 'password123!';

      final (isValid, message) =
          PasswordHashingService.validatePasswordStrength(noUpperPassword);

      expect(isValid, false);
      expect(message, contains('uppercase'));
    });

    test('Password validation should require lowercase', () {
      const noLowerPassword = 'PASSWORD123!';

      final (isValid, message) =
          PasswordHashingService.validatePasswordStrength(noLowerPassword);

      expect(isValid, false);
      expect(message, contains('lowercase'));
    });

    test('Password validation should require numbers', () {
      const noNumberPassword = 'PasswordABC!';

      final (isValid, message) =
          PasswordHashingService.validatePasswordStrength(noNumberPassword);

      expect(isValid, false);
      expect(message, contains('number'));
    });

    test('Password validation should require special characters', () {
      const noSpecialPassword = 'Password123';

      final (isValid, message) =
          PasswordHashingService.validatePasswordStrength(noSpecialPassword);

      expect(isValid, false);
      expect(message, contains('special character'));
    });

    test('Password validation should accept strong password', () {
      const strongPassword = 'MySecure123!Pass';

      final (isValid, message) =
          PasswordHashingService.validatePasswordStrength(strongPassword);

      expect(isValid, true);
      expect(message, isNull);
    });

    test('Generate secure token should create random tokens', () {
      final token1 = PasswordHashingService.generateSecureToken(32);
      final token2 = PasswordHashingService.generateSecureToken(32);

      expect(token1, isNot(equals(token2)));
      expect(token1.length, greaterThan(0));
      expect(token2.length, greaterThan(0));
    });

    test('Hash data should be consistent for same input', () {
      const data = 'Some data to hash';

      final hash1 = PasswordHashingService.hashData(data);
      final hash2 = PasswordHashingService.hashData(data);

      // SHA-256 should be deterministic
      expect(hash1, equals(hash2));
    });

    test('Hash data should be different for different input', () {
      const data1 = 'First data';
      const data2 = 'Second data';

      final hash1 = PasswordHashingService.hashData(data1);
      final hash2 = PasswordHashingService.hashData(data2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Verify password should handle empty password gracefully', () async {
      const password = 'ValidPassword123!';
      const emptyPassword = '';

      final hash = await PasswordHashingService.hashPassword(password);
      final isValid =
          await PasswordHashingService.verifyPassword(emptyPassword, hash);

      expect(isValid, false);
    });

    test('Verify password should handle invalid hash gracefully', () async {
      const password = 'SomePassword123!';
      const invalidHash = 'not-a-valid-hash';

      // Should not throw, just return false
      final isValid =
          await PasswordHashingService.verifyPassword(password, invalidHash);

      expect(isValid, false);
    });

    test('Multiple hashes should all be verifiable', () async {
      const password = 'MultiTest123!';
      const iterations = 5;

      final hashes = <String>[];

      // Create multiple hashes
      for (var i = 0; i < iterations; i++) {
        final hash = await PasswordHashingService.hashPassword(password);
        hashes.add(hash);
      }

      // All should be unique
      expect(hashes.toSet().length, iterations);

      // All should verify correctly
      for (final hash in hashes) {
        final isValid =
            await PasswordHashingService.verifyPassword(password, hash);
        expect(isValid, true);
      }
    });
  });
}
