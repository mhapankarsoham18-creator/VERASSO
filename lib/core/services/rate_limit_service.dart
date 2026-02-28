import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import '../utils/network_util.dart';
import 'supabase_service.dart';

// Riverpod provider for rate limiting service
/// Provider for the [RateLimitService] instance.
final rateLimitServiceProvider = Provider((ref) {
  return RateLimitService();
});

/// Represents a recorded attempt for a rate-limited action.
class RateLimitAttempt {
  /// The unique identifier for the entity (e.g., user ID, email, IP).
  final String identifier;

  /// The category of action being tracked.
  final String type;

  /// The reason for recording the attempt (e.g., 'failed_login').
  final String reason;

  /// The timestamp of the attempt.
  final DateTime attemptedAt;

  /// Creates a [RateLimitAttempt].
  RateLimitAttempt({
    required this.identifier,
    required this.type,
    required this.reason,
    required this.attemptedAt,
  });

  /// Creates a [RateLimitAttempt] from a JSON map.
  factory RateLimitAttempt.fromJson(Map<String, dynamic> json) {
    return RateLimitAttempt(
      identifier: json['identifier'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String,
      attemptedAt: DateTime.parse(json['attempted_at'] as String),
    );
  }
}

/// Configuration for a specific rate limit window.
class RateLimitConfig {
  /// The maximum number of allowed attempts within the window.
  final int maxAttempts;

  /// The duration of the tracking window in minutes.
  final int windowMinutes;

  /// The duration of the penalty lockout in minutes if limit is exceeded.
  final int lockoutMinutes;

  /// Creates a [RateLimitConfig].
  const RateLimitConfig({
    required this.maxAttempts,
    required this.windowMinutes,
    required this.lockoutMinutes,
  });
}

/// Service for preventing abuse and brute-force attacks via rate limiting.
///
/// It tracks failed interactions and enforces cooldown periods for critical actions.
class RateLimitService {
  static const String _tableName = 'rate_limit_attempts';

  // Rate limit configurations
  /// Predefined configurations for various [RateLimitType]s.
  static const Map<RateLimitType, RateLimitConfig> configs = {
    RateLimitType.login: RateLimitConfig(
      maxAttempts: 5,
      windowMinutes: 15,
      lockoutMinutes: 30,
    ),
    RateLimitType.passwordReset: RateLimitConfig(
      maxAttempts: 3,
      windowMinutes: 60,
      lockoutMinutes: 120,
    ),
    RateLimitType.signup: RateLimitConfig(
      maxAttempts: 2,
      windowMinutes: 60,
      lockoutMinutes: 240,
    ),
    RateLimitType.mfaVerification: RateLimitConfig(
      maxAttempts: 5,
      windowMinutes: 10,
      lockoutMinutes: 30,
    ),
    RateLimitType.sendEmail: RateLimitConfig(
      maxAttempts: 5,
      windowMinutes: 60,
      lockoutMinutes: 60,
    ),
    // Messaging rate limits for 5k-10k daily users
    RateLimitType.sendMessage: RateLimitConfig(
      maxAttempts: 50, // 50 messages per minute (3000/hour, 72k/day per user)
      windowMinutes: 1,
      lockoutMinutes: 5,
    ),
    RateLimitType.uploadAttachment: RateLimitConfig(
      maxAttempts: 10, // 10 uploads per minute
      windowMinutes: 1,
      lockoutMinutes: 10,
    ),
    RateLimitType.searchMessages: RateLimitConfig(
      maxAttempts: 30, // 30 searches per minute
      windowMinutes: 1,
      lockoutMinutes: 5,
    ),
    RateLimitType.createPost: RateLimitConfig(
      maxAttempts: 10, // 10 posts per hour
      windowMinutes: 60,
      lockoutMinutes: 30,
    ),
    RateLimitType.apiCall: RateLimitConfig(
      maxAttempts: 300, // 300 API calls per minute per user
      windowMinutes: 1,
      lockoutMinutes: 5,
    ),
    RateLimitType.globalSearch: RateLimitConfig(
      maxAttempts: 20, // 20 global searches per minute
      windowMinutes: 1,
      lockoutMinutes: 5,
    ),
  };

  final SupabaseClient _client;

  /// Creates a [RateLimitService], optionally with a custom [SupabaseClient].
  RateLimitService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Clean up old attempts (run periodically via background task)
  Future<void> cleanupOldAttempts({int olderThanDays = 7}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));

      await _client
          .from(_tableName)
          .delete()
          .lt('attempted_at', cutoff.toIso8601String());

      AppLogger.info(
        'Cleaned up rate limit attempts older than $olderThanDays days',
      );
    } catch (e, stack) {
      AppLogger.error('RateLimitService cleanup error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Clear attempts for an identifier and type
  Future<void> clearAttempts(String identifier, RateLimitType type) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('identifier', identifier)
          .eq('type', type.name);

      AppLogger.info('Cleared attempts for $identifier (${type.name})');
    } catch (e, stack) {
      AppLogger.error('RateLimitService clear attempts error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Get attempt history for audit logging
  Future<List<RateLimitAttempt>> getAttemptHistory(
    String identifier,
    RateLimitType type, {
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('identifier', identifier)
          .eq('type', type.name)
          .order('attempted_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => RateLimitAttempt.fromJson(e))
          .toList();
    } catch (e, stack) {
      AppLogger.error('RateLimitService get attempt history error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Get lockout time remaining in minutes
  Future<int> getLockoutTimeRemaining(
    String identifier,
    RateLimitType type,
  ) async {
    try {
      final config = configs[type]!;
      final now = DateTime.now();
      final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

      final response = await _client
          .from(_tableName)
          .select()
          .eq('identifier', identifier)
          .eq('type', type.name)
          .gte('attempted_at', windowStart.toIso8601String())
          .order('attempted_at', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) {
        return 0; // No lockout
      }

      final lastAttempt = DateTime.parse(
        response.first['attempted_at'] as String,
      );
      final lockoutEnd = lastAttempt.add(
        Duration(minutes: config.lockoutMinutes),
      );
      final remaining = lockoutEnd.difference(now).inMinutes;

      return remaining > 0 ? remaining : 0;
    } catch (e, stack) {
      AppLogger.error('RateLimitService get lockout time remaining error',
          error: e);
      SentryService.captureException(e, stackTrace: stack);
      return 0;
    }
  }

  /// Get remaining attempts before lockout
  Future<int> getRemainingAttempts(
    String identifier,
    RateLimitType type,
  ) async {
    try {
      final config = configs[type]!;
      final now = DateTime.now();
      final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

      final response = await _client
          .from(_tableName)
          .select()
          .eq('identifier', identifier)
          .eq('type', type.name)
          .gte('attempted_at', windowStart.toIso8601String());

      final attempts = response as List;
      final remaining = config.maxAttempts - attempts.length;

      return remaining > 0 ? remaining : 0;
    } catch (e, stack) {
      AppLogger.error('RateLimitService get remaining attempts error',
          error: e);
      SentryService.captureException(e, stackTrace: stack);
      return -1; // Error state
    }
  }

  /// Check if an action is rate limited
  /// Returns true if limit exceeded, false if allowed
  Future<bool> isLimited(String identifier, RateLimitType type) async {
    try {
      final config = configs[type]!;

      // NEW: Call server-side RPC for enforcement
      // This is much safer as it uses the same source of truth for all clients
      final response = await _client.rpc('check_rate_limit', params: {
        'p_user_id': _client.auth.currentUser?.id,
        'p_ip_address': await NetworkUtil.getIpAddress(),
        'p_endpoint': type.name,
      });

      if (response != null && response['allowed'] == false) {
        AppLogger.warning('Server-side rate limit hit for ${type.name}');
        return true;
      }

      // Fallback/Legacy: Local check or additional verification
      final now = DateTime.now();
      final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

      // Get recent attempts within the window
      final localResponse = await _client
          .from(_tableName)
          .select()
          .eq('identifier', identifier)
          .eq('type', type.name)
          .gte('attempted_at', windowStart.toIso8601String())
          .order('attempted_at', ascending: false);

      final attempts = localResponse as List;

      // Check if locked out
      if (attempts.length >= config.maxAttempts) {
        final lastAttempt = DateTime.parse(
          attempts.first['attempted_at'] as String,
        );
        final lockoutEnd = lastAttempt.add(
          Duration(minutes: config.lockoutMinutes),
        );

        if (now.isBefore(lockoutEnd)) {
          AppLogger.info('Rate limit exceeded for $identifier (${type.name})');
          return true; // Still locked out
        } else {
          // Lockout period expired, clear old attempts
          await _clearOldAttempts(identifier, type);
          return false; // Allow
        }
      }

      return false; // Allow
    } catch (e, stack) {
      AppLogger.error('RateLimitService isLimited error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      // Fail open - allow access on error
      return false;
    }
  }

  /// Log an authentication attempt for rate limiting tracking
  /// This is an alias/wrapper for recordAttempt for backward compatibility
  Future<void> logAttempt({
    required String email,
    required String action,
    required bool success,
    String? ip,
  }) async {
    // Map action string to RateLimitType
    RateLimitType type;
    switch (action.toLowerCase()) {
      case 'login':
        type = RateLimitType.login;
        break;
      case 'signup':
        type = RateLimitType.signup;
        break;
      case 'password_reset':
        type = RateLimitType.passwordReset;
        break;
      case 'mfa_verification':
        type = RateLimitType.mfaVerification;
        break;
      default:
        type = RateLimitType.login; // Default fallback
    }

    // Only record failed attempts for rate limiting
    if (!success) {
      await recordAttempt(
        email,
        type,
        reason: 'failed_$action${ip != null ? "_from_$ip" : ""}',
      );
    }
  }

  /// Record a failed attempt
  Future<void> recordAttempt(
    String identifier,
    RateLimitType type, {
    String? reason,
  }) async {
    try {
      await _client.from(_tableName).insert({
        'identifier': identifier,
        'type': type.name,
        'reason': reason ?? 'failed_attempt',
        'attempted_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Recorded attempt for $identifier (${type.name})');
    } catch (e, stack) {
      AppLogger.error('RateLimitService record attempt error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Delete old attempts outside any window
  Future<void> _clearOldAttempts(String identifier, RateLimitType type) async {
    try {
      final config = configs[type]!;
      final cutoff = DateTime.now().subtract(
        Duration(minutes: config.lockoutMinutes),
      );

      await _client
          .from(_tableName)
          .delete()
          .eq('identifier', identifier)
          .eq('type', type.name)
          .lt('attempted_at', cutoff.toIso8601String());
    } catch (e, stack) {
      AppLogger.error('RateLimitService clear old attempts error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}

/// Defines categories of actions that are subject to rate limiting.
enum RateLimitType {
  /// Standard user login attempts.
  login,

  /// Requests for password recovery emails.
  passwordReset,

  /// New user account creation attempts.
  signup,

  /// Multi-factor authentication code verifications.
  mfaVerification,

  /// General outbound email delivery requests.
  sendEmail,

  /// Sending direct messages.
  sendMessage,

  /// Uploading message attachments/files.
  uploadAttachment,

  /// Searching within messages.
  searchMessages,

  /// Creating new posts/content.
  createPost,

  /// General API call tracking.
  apiCall,

  /// Performing global search across content.
  globalSearch,
}
