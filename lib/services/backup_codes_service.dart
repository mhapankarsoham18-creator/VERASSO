import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for a backup code
/// Represents a one-time use backup code for 2FA.
class BackupCode {
  /// Unique identifier for the backup code.
  final String id;

  /// The ID of the user this code belongs to.
  final String userId;

  /// The hashed version of the backup code.
  final String codeHash;

  /// Whether the code has already been used.
  final bool isUsed;

  /// The date and time when the code was used, if applicable.
  final DateTime? usedAt;

  /// The date and time when the code was created.
  final DateTime createdAt;

  /// Creates a [BackupCode] instance.
  BackupCode({
    required this.id,
    required this.userId,
    required this.codeHash,
    required this.isUsed,
    this.usedAt,
    required this.createdAt,
  });

  /// Creates a [BackupCode] from a JSON map.
  factory BackupCode.fromJson(Map<String, dynamic> json) {
    return BackupCode(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      codeHash: json['code_hash'] as String,
      isUsed: json['is_used'] as bool,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Service for managing two-factor authentication (2FA) backup codes.
class BackupCodesService {
  final _supabase = Supabase.instance.client;

  /// Generate 10 new backup codes for the current user
  /// Returns the plain codes (only time they're visible)
  /// WARNING: Store these codes securely!
  Future<List<String>> generateBackupCodes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Call the Supabase function to generate codes
      final response = await _supabase.rpc(
        'generate_backup_codes',
        params: {'p_user_id': userId},
      ) as List<dynamic>;

      // Extract plain codes from response
      final codes = response
          .map((item) => (item as Map<String, dynamic>)['code'] as String)
          .toList();

      return codes;
    } catch (e) {
      throw Exception('Failed to generate backup codes: $e');
    }
  }

  /// Get all backup codes for current user (for display purposes)
  /// Note: This only returns metadata, not the actual codes
  Future<List<BackupCode>> getBackupCodes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_backup_codes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => BackupCode.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch backup codes: $e');
    }
  }

  /// Get count of unused backup codes for current user
  Future<int> getUnusedCodesCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final count = await _supabase.rpc(
        'count_unused_backup_codes',
        params: {'p_user_id': userId},
      ) as int;

      return count;
    } catch (e) {
      throw Exception('Failed to get unused codes count: $e');
    }
  }

  /// Check if user has any backup codes
  Future<bool> hasBackupCodes() async {
    try {
      final count = await getUnusedCodesCount();
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Regenerate all backup codes (invalidates old ones)
  /// Returns the new plain codes
  Future<List<String>> regenerateBackupCodes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'regenerate_backup_codes',
        params: {'p_user_id': userId},
      ) as List<dynamic>;

      final codes = response
          .map((item) => (item as Map<String, dynamic>)['code'] as String)
          .toList();

      return codes;
    } catch (e) {
      throw Exception('Failed to regenerate backup codes: $e');
    }
  }

  /// Verify a backup code during login
  /// Returns true if valid and unused, false otherwise
  /// Marks the code as used if valid
  Future<bool> verifyBackupCode(String code) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'verify_backup_code',
        params: {
          'p_user_id': userId,
          'p_code': code.toUpperCase().trim(),
        },
      ) as bool;

      return response;
    } catch (e) {
      throw Exception('Failed to verify backup code: $e');
    }
  }
}
