import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/password_hashing_service.dart';

void main() {
  group('Password Storage Verification', () {
    test('Password MUST be transformed into a hash before storage', () async {
      // 1. The plain password the user enters
      const plainPassword = 'MySecretPassword123!';

      debugPrint('--- Verification Step 1: Input ---');
      debugPrint('User Input: "$plainPassword"');

      // 2. Perform the hashing (simulating what the service does)
      // This includes adding random padding + generating a unique salt via bcrypt
      final storedHash =
          await PasswordHashingService.hashPassword(plainPassword);

      debugPrint('\n--- Verification Step 2: Output for Database ---');
      debugPrint('Stored Value: "$storedHash"');

      // 3. CRITICAL SECURITY CHECKS

      // Check A: The stored value MUST NOT match the plain password
      expect(storedHash, isNot(equals(plainPassword)),
          reason: 'SECURITY CRITICAL: Password is stored in plain text!');

      // Check B: The stored value MUST NOT contain the plain password as a substring
      expect(storedHash.contains(plainPassword), false,
          reason: 'SECURITY CRITICAL: Plain password found inside the hash!');

      // Check C: The stored value MUST follow Bcrypt format
      // Format: $2a$[cost]$[22 char salt][31 char hash]
      expect(storedHash.startsWith(RegExp(r'\$2[aby]\$')), true,
          reason: 'Stored value is not a valid Bcrypt hash');

      debugPrint('\n--- Verification Step 3: Analysis ---');
      debugPrint('✅ Check A Passed: Stored value differs from input.');
      debugPrint('✅ Check B Passed: Input does not appear in stored value.');
      debugPrint('✅ Check C Passed: Format is valid Bcrypt hash.');
    });

    test('Two identical passwords MUST produce different hashes (Salting)',
        () async {
      const password = 'SamePassword123!';

      debugPrint('\n--- Verification Step 4: Salting Check ---');
      debugPrint('Input 1: "$password"');
      debugPrint('Input 2: "$password"');

      final hash1 = await PasswordHashingService.hashPassword(password);
      final hash2 = await PasswordHashingService.hashPassword(password);

      debugPrint('Hash 1: "$hash1"');
      debugPrint('Hash 2: "$hash2"');

      // If they are equal, it means no random salt was used (bad!)
      expect(hash1, isNot(equals(hash2)),
          reason:
              'SECURITY CRITICAL: Identical passwords produced identical hashes! Salt is missing or checking failed.');

      debugPrint(
          '✅ Check D Passed: Identical passwords produced unique hashes (Salt is working).');
    });
  });
}
