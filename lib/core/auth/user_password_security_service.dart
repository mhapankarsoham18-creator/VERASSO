import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/security/password_hashing_service.dart';
import '../../features/messaging/services/encryption_service.dart';

/// Complete user password management with advanced security
class UserPasswordSecurityService {
  final SupabaseClient _supabase;
  final EncryptionService _encryption;

  /// Creates a [UserPasswordSecurityService].
  ///
  /// If [encryption] is not provided, it initializes a new [EncryptionService]
  /// using the provided [SupabaseClient].
  UserPasswordSecurityService(this._supabase, {EncryptionService? encryption})
      : _encryption = encryption ?? EncryptionService(client: _supabase);

  // ============================================================
  // PASSWORD MANAGEMENT
  // ============================================================

  /// Create password reset token
  Future<String> createPasswordResetToken(String userId) async {
    // Generate secure random token
    final token = PasswordHashingService.generateSecureToken(32);

    // Hash token with SHA-256
    final tokenHash = _hashToken(token);

    // Store hashed token in database
    await _supabase.rpc('create_recovery_token', params: {
      'p_user_id': userId,
      'p_token_hash': tokenHash,
      'p_token_type': 'password_reset',
      'p_expires_in_hours': 24,
    });

    // Return plain token (only shown once to user)
    return token;
  }

  /// Enable SMS 2FA
  Future<void> enableSMS(String userId, String phoneNumber) async {
    final encData = await _encryption.encryptMessage(phoneNumber, userId);
    final encryptedPhone = jsonEncode(encData);

    await _supabase.rpc('enable_2fa', params: {
      'p_user_id': userId,
      'p_method': 'sms',
      'p_phone_number': encryptedPhone,
    });
  }

  /// Enable TOTP 2FA
  Future<String> enableTOTP(String userId, String totpSecret) async {
    // Encrypt for self so we can decrypt it later in the UI if needed
    final encData = await _encryption.encryptMessage(totpSecret, userId);
    final encryptedSecret = jsonEncode(encData);

    await _supabase.rpc('enable_2fa', params: {
      'p_user_id': userId,
      'p_method': 'totp',
      'p_secret': encryptedSecret,
    });

    return totpSecret;
  }

  // ============================================================
  // PASSWORD RECOVERY
  // ============================================================

  /// Get password change history
  Future<List<Map<String, dynamic>>> getPasswordChangeHistory(
      String userId) async {
    final response = await _supabase
        .from('password_change_log')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get security questions library
  Future<List<Map<String, dynamic>>> getSecurityQuestions() async {
    final response = await _supabase
        .from('security_questions_library')
        .select()
        .eq('is_active', true)
        .order('category');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user security status
  Future<Map<String, dynamic>> getSecurityStatus(String userId) async {
    final response = await _supabase
        .from('user_security_status')
        .select()
        .eq('user_id', userId)
        .single();

    return response;
  }

  // ============================================================
  // SECURITY QUESTIONS
  // ============================================================

  /// Check if user has 2FA enabled
  Future<bool> is2FAEnabled(String userId) async {
    final response = await _supabase
        .from('user_2fa')
        .select('id')
        .eq('user_id', userId)
        .eq('is_enabled', true)
        .maybeSingle();

    return response != null;
  }

  /// Check if password is expired
  Future<bool> isPasswordExpired(String userId) async {
    final response = await _supabase
        .from('user_passwords')
        .select('expires_at')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null || response['expires_at'] == null) {
      return false;
    }

    final expiresAt = DateTime.parse(response['expires_at'] as String);
    return expiresAt.isBefore(DateTime.now());
  }

  /// Reset password using token
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    // Verify token and get user ID
    final userId = await verifyPasswordResetToken(token);
    if (userId == null) {
      throw Exception('Invalid or expired reset token');
    }

    // Set new password
    await setPassword(userId: userId, password: newPassword);

    // Log reset
    await _supabase.rpc('log_password_change', params: {
      'p_user_id': userId,
      'p_change_type': 'reset',
      'p_new_strength': _calculatePasswordStrength(newPassword),
      'p_reason': 'Password reset via recovery token',
    });
  }

  // ============================================================
  // TWO-FACTOR AUTHENTICATION
  // ============================================================

  /// Set user password with bcrypt hashing and security tracking
  Future<void> setPassword({
    required String userId,
    required String password,
  }) async {
    // Validate password strength
    final (isValid, errorMessage) =
        PasswordHashingService.validatePasswordStrength(password);

    if (!isValid) {
      throw Exception(errorMessage);
    }

    // Hash password with bcrypt (includes automatic salt and padding)
    final passwordHash = await PasswordHashingService.hashPassword(password);

    // Calculate password metrics
    final strength = _calculatePasswordStrength(password);
    final metadata = {
      'has_uppercase': password.contains(RegExp(r'[A-Z]')),
      'has_lowercase': password.contains(RegExp(r'[a-z]')),
      'has_numbers': password.contains(RegExp(r'[0-9]')),
      'has_special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      'created_at': DateTime.now().toIso8601String(),
    };

    // Store in database using secure function
    await _supabase.rpc('set_user_password', params: {
      'p_user_id': userId,
      'p_password_hash': passwordHash,
      'p_strength_score': strength,
      'p_password_length': password.length,
      'p_metadata': metadata,
    });

    // Log password change
    await _supabase.rpc('log_password_change', params: {
      'p_user_id': userId,
      'p_change_type': 'created',
      'p_new_strength': strength,
    });
  }

  /// Set security question and answer
  Future<void> setSecurityQuestion({
    required String userId,
    required int questionId,
    required String questionText,
    required String answer,
  }) async {
    // Hash answer with bcrypt (case-insensitive)
    final normalizedAnswer = answer.toLowerCase().trim();
    final answerHash =
        await PasswordHashingService.hashPassword(normalizedAnswer);

    await _supabase.from('user_security_questions').upsert({
      'user_id': userId,
      'question_id': questionId,
      'question_text': questionText,
      'answer_hash': answerHash,
    });
  }

  /// Update existing password
  Future<void> updatePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    // Verify old password first
    final isValid = await verifyPassword(userId: userId, password: oldPassword);
    if (!isValid) {
      throw Exception('Current password is incorrect');
    }

    // Check if new password was used before (prevents reuse)
    final newPasswordHash =
        await PasswordHashingService.hashPassword(newPassword);
    final isReused = await _supabase.rpc('is_password_reused', params: {
      'p_user_id': userId,
      'p_new_password_hash': newPasswordHash,
    }) as bool;

    if (isReused) {
      throw Exception(
          'Password was used previously. Please choose a different password.');
    }

    // Get old strength
    final oldStrength = await _getPasswordStrength(userId);

    // Set new password
    await setPassword(userId: userId, password: newPassword);

    // Log change
    await _supabase.rpc('log_password_change', params: {
      'p_user_id': userId,
      'p_change_type': 'updated',
      'p_old_strength': oldStrength,
      'p_new_strength': _calculatePasswordStrength(newPassword),
      'p_reason': 'User-initiated password change',
    });
  }

  // ============================================================
  // PASSWORD ANALYTICS
  // ============================================================

  /// Verify user password
  Future<bool> verifyPassword({
    required String userId,
    required String password,
  }) async {
    try {
      // Get stored password hash
      final response = await _supabase
          .from('user_passwords')
          .select('password_hash')
          .eq('user_id', userId)
          .single();

      final storedHash = response['password_hash'] as String;

      // Verify using bcrypt
      return await PasswordHashingService.verifyPassword(password, storedHash);
    } catch (e) {
      return false;
    }
  }

  /// Verify and use password reset token
  Future<String?> verifyPasswordResetToken(String token) async {
    final tokenHash = _hashToken(token);

    final response = await _supabase.rpc('verify_recovery_token', params: {
      'p_token_hash': tokenHash,
    }) as Map<String, dynamic>;

    if (response['valid'] == true) {
      return response['user_id'] as String;
    }

    return null;
  }

  /// Verify security question answer
  Future<bool> verifySecurityAnswer({
    required String userId,
    required int questionId,
    required String answer,
  }) async {
    try {
      final response = await _supabase
          .from('user_security_questions')
          .select('answer_hash')
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .single();

      final storedHash = response['answer_hash'] as String;
      final normalizedAnswer = answer.toLowerCase().trim();

      return await PasswordHashingService.verifyPassword(
          normalizedAnswer, storedHash);
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  int _calculatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Future<int> _getPasswordStrength(String userId) async {
    try {
      final response = await _supabase
          .from('user_passwords')
          .select('strength_score')
          .eq('user_id', userId)
          .single();

      return response['strength_score'] as int;
    } catch (e) {
      return 0;
    }
  }

  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
