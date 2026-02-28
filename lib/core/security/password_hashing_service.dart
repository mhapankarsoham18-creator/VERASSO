import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

/// Secure password hashing service using bcrypt.
///
/// Implements salting, random padding, and secure verification to protect
/// user credentials against brute-force and rainbow table attacks.
class PasswordHashingService {
  /// Bcrypt work factor (cost) - higher = more secure but slower.
  /// 12 is a good balance for current hardware.
  static const int workFactor = 12;

  /// Random padding length for additional security when generating tokens.
  static const int paddingLength = 16;

  /// Generate a secure random token
  static String generateSecureToken([int length = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash data with SHA-256 (for non-password data)
  /// Hashes arbitrary string data using SHA-256.
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash a password with bcrypt
  ///
  /// Process:
  /// 1. Generate unique bcrypt salt (automatic)
  /// 2. Hash password with bcrypt
  /// 3. Return hash (contains salt embedded)
  ///
  /// Returns: Bcrypt hash string (contains salt)
  static Future<String> hashPassword(String password) async {
    try {
      // Bcrypt automatically generates unique salt and embeds it in hash
      // Work factor of 12 means 2^12 = 4096 iterations
      final hashedPassword =
          BCrypt.hashpw(password, BCrypt.gensalt(logRounds: workFactor));

      return hashedPassword;
    } catch (e) {
      throw Exception('Failed to hash password: $e');
    }
  }

  /// Validate password strength
  /// Returns: (isValid, errorMessage)
  /// Validates the strength of a password against security policies.
  ///
  /// Returns a tuple containing a boolean (valid/invalid) and an optional
  /// error message describing why the password failed validation.
  static (bool, String?) validatePasswordStrength(String password) {
    if (password.length < 8) {
      return (false, 'Password must be at least 8 characters');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return (false, 'Password must contain at least one uppercase letter');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return (false, 'Password must contain at least one lowercase letter');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return (false, 'Password must contain at least one number');
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return (false, 'Password must contain at least one special character');
    }

    return (true, null);
  }

  /// Verify a password against a bcrypt hash
  ///
  /// Process:
  /// 1. Extract salt from stored hash (bcrypt does this automatically)
  /// 2. Hash input with extracted salt
  /// 3. Compare hashes using constant-time comparison
  ///
  /// Returns: true if password matches
  static Future<bool> verifyPassword(
      String password, String hashedPassword) async {
    try {
      // BCrypt.checkpw uses constant-time comparison to prevent timing attacks
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      // If anything goes wrong, return false (don't leak information)
      return false;
    }
  }
}
