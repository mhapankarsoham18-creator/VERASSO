import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/security/encryption_service.dart';
import '../../../core/security/password_hashing_service.dart';
import '../../../core/security/security_initializer.dart';

/// Provider for the [ArSecurityRepository].
final arSecurityRepositoryProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final encryption = ref.watch(encryptionServiceProvider);
  return ArSecurityRepository(supabase, encryption);
});

/// Provider for the [EncryptionService] used by security repositories.
final encryptionServiceProvider =
    Provider((ref) => SecurityInitializer.encryptionService);

/// Security repository for AR projects
class ArSecurityRepository {
  final SupabaseClient _supabase;
  final EncryptionService _encryptionService;

  /// Creates an [ArSecurityRepository] instance.
  ArSecurityRepository(this._supabase, this._encryptionService);

  // ============================================================
  // PASSWORD PROTECTION
  // ============================================================

  /// Create encrypted backup
  Future<String> createEncryptedBackup({
    required String projectId,
    String? password,
  }) async {
    try {
      // Get project data
      final project = await _supabase
          .from('ar_projects')
          .select()
          .eq('id', projectId)
          .single();

      // Encrypt project data
      final encryptedData = await encryptProjectData(
        project,
        password: password,
      );

      // Generate encryption key ID
      final keyId = PasswordHashingService.generateSecureToken(16);

      // Store backup via database function
      final response = await _supabase.rpc('create_project_backup', params: {
        'p_project_id': projectId,
        'p_encrypted_data': encryptedData,
        'p_encryption_key_id': keyId,
      });

      final backupId = response as String;

      await _logSecurityEvent(
        projectId: projectId,
        action: 'backup_created',
        result: 'success',
        metadata: {'backup_id': backupId},
      );

      return backupId;
    } catch (e) {
      await _logSecurityEvent(
        projectId: projectId,
        action: 'backup_created',
        result: 'failure',
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Decrypt project data
  Future<String> decryptProjectData(String encryptedData,
      {String? password}) async {
    if (password != null) {
      return _encryptionService.decryptWithPassword(encryptedData, password);
    } else {
      return _encryptionService.decrypt(encryptedData);
    }
  }

  /// Encrypt project data
  Future<String> encryptProjectData(Map<String, dynamic> projectData,
      {String? password}) async {
    final jsonData = projectData.toString();

    if (password != null) {
      // Encrypt with password
      return _encryptionService.encryptWithPassword(jsonData, password);
    } else {
      // Encrypt with master key
      return _encryptionService.encrypt(jsonData);
    }
  }

  /// Encrypt specific fields in project
  Future<void> encryptProjectFields({
    required String projectId,
    required List<String> fieldsToEncrypt,
  }) async {
    // Get project
    final project = await _supabase
        .from('ar_projects')
        .select()
        .eq('id', projectId)
        .single();

    // Encrypt specified fields
    final fieldEncryption = FieldEncryptionService(_encryptionService);
    final encryptedProject = await fieldEncryption.encryptFields(
      project,
      fieldsToEncrypt,
    );

    // Update project with encrypted fields
    await _supabase.from('ar_projects').update({
      ...encryptedProject,
      'is_encrypted': true,
      'encrypted_fields': fieldsToEncrypt,
    }).eq('id', projectId);

    await _logSecurityEvent(
      projectId: projectId,
      action: 'fields_encrypted',
      result: 'success',
      metadata: {'fields': fieldsToEncrypt},
    );
  }

  /// Get security audit log for a project
  Future<List<Map<String, dynamic>>> getAuditLog({
    required String projectId,
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('ar_security_audit_log')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // ENCRYPTION
  // ============================================================

  /// Get password hint
  Future<String?> getPasswordHint(String projectId) async {
    final response = await _supabase
        .from('ar_project_passwords')
        .select('hint')
        .eq('project_id', projectId)
        .maybeSingle();

    return response?['hint'] as String?;
  }

  /// Get user's security audit log
  Future<List<Map<String, dynamic>>> getUserAuditLog({
    int limit = 100,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('ar_security_audit_log')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Check if project is password protected
  Future<bool> isProjectPasswordProtected(String projectId) async {
    final response = await _supabase
        .from('ar_project_passwords')
        .select('id')
        .eq('project_id', projectId)
        .maybeSingle();

    return response != null;
  }

  // ============================================================
  // BACKUPS
  // ============================================================

  /// List backups for a project
  Future<List<Map<String, dynamic>>> listBackups(String projectId) async {
    final response = await _supabase
        .from('ar_project_backups')
        .select('id, created_at, expires_at')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Remove password protection
  Future<void> removeProjectPassword(String projectId) async {
    await _supabase
        .from('ar_project_passwords')
        .delete()
        .eq('project_id', projectId);

    await _logSecurityEvent(
      projectId: projectId,
      action: 'password_removed',
      result: 'success',
    );
  }

  /// Restore from encrypted backup
  Future<Map<String, dynamic>> restoreFromBackup({
    required String backupId,
    String? password,
  }) async {
    try {
      // Verify integrity first
      final isValid = await _supabase.rpc('verify_backup_integrity', params: {
        'p_backup_id': backupId,
      }) as bool;

      if (!isValid) {
        throw Exception('Backup integrity check failed');
      }

      // Get backup data
      final backup = await _supabase
          .from('ar_project_backups')
          .select('backup_data, project_id')
          .eq('id', backupId)
          .single();

      final encryptedData = backup['backup_data'] as String;
      final projectId = backup['project_id'] as String;

      // Decrypt data
      final decryptedData = await decryptProjectData(
        encryptedData,
        password: password,
      );

      await _logSecurityEvent(
        projectId: projectId,
        action: 'backup_restored',
        result: 'success',
        metadata: {'backup_id': backupId},
      );

      // Parse and return
      // Note: You may need to properly parse the data format
      return {'data': decryptedData};
    } catch (e) {
      await _logSecurityEvent(
        projectId: 'unknown',
        action: 'backup_restored',
        result: 'failure',
        metadata: {'backup_id': backupId, 'error': e.toString()},
      );
      rethrow;
    }
  }

  // ============================================================
  // AUDIT LOGGING
  // ============================================================

  /// Set password protection for a project
  Future<void> setProjectPassword({
    required String projectId,
    required String password,
    String? hint,
  }) async {
    try {
      // Validate password strength
      final (isValid, errorMessage) =
          PasswordHashingService.validatePasswordStrength(password);

      if (!isValid) {
        throw Exception(errorMessage);
      }

      // Hash password with bcrypt (salt is embedded in hash)
      final passwordHash = await PasswordHashingService.hashPassword(password);

      // Store in database
      await _supabase.from('ar_project_passwords').upsert({
        'project_id': projectId,
        'password_hash': passwordHash,
        'hint': hint,
        'encryption_metadata': {
          'algorithm': 'bcrypt',
          'work_factor': PasswordHashingService.workFactor,
          'created_at': DateTime.now().toIso8601String(),
        },
      });

      // Log security event
      await _logSecurityEvent(
        projectId: projectId,
        action: 'password_set',
        result: 'success',
      );
    } catch (e) {
      await _logSecurityEvent(
        projectId: projectId,
        action: 'password_set',
        result: 'failure',
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Verify project password
  Future<bool> verifyProjectPassword({
    required String projectId,
    required String password,
  }) async {
    try {
      // Get stored password hash
      final response = await _supabase
          .from('ar_project_passwords')
          .select('password_hash, locked_until, failed_attempts')
          .eq('project_id', projectId)
          .single();

      // Check if locked
      if (response['locked_until'] != null) {
        final lockedUntil = DateTime.parse(response['locked_until'] as String);
        if (lockedUntil.isAfter(DateTime.now())) {
          await _logSecurityEvent(
            projectId: projectId,
            action: 'password_attempt',
            result: 'locked',
          );
          throw Exception('Project is locked. Try again later.');
        }
      }

      final passwordHash = response['password_hash'] as String;

      // Verify password
      final isValid = await PasswordHashingService.verifyPassword(
        password,
        passwordHash,
      );

      // Update attempt counter via database function
      await _supabase.rpc('check_password_attempt', params: {
        'p_project_id': projectId,
        'p_success': isValid,
      });

      // Log attempt
      await _logSecurityEvent(
        projectId: projectId,
        action: 'password_attempt',
        result: isValid ? 'success' : 'failure',
      );

      return isValid;
    } catch (e) {
      await _logSecurityEvent(
        projectId: projectId,
        action: 'password_attempt',
        result: 'error',
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Log security event
  Future<void> _logSecurityEvent({
    required String projectId,
    required String action,
    required String result,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.rpc('log_security_event', params: {
        'p_user_id': _supabase.auth.currentUser?.id,
        'p_project_id': projectId,
        'p_action': action,
        'p_result': result,
        'p_metadata': metadata ?? {},
      });
    } catch (e) {
      // Don't throw on logging errors
      AppLogger.info('Failed to log security event: $e');
    }
  }
}
