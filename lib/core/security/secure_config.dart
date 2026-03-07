/// Secure configuration management for API keys and secrets.
///
/// ALL secrets are injected at build time via --dart-define flags.
/// NO secret should EVER be hardcoded in source code or committed to git.
///
/// Build command example:
/// ```bash
/// flutter build apk \
///   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=your-key \
///   --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/123 \
///   --dart-define=GEMINI_API_KEY=your-gemini-key \
///   --dart-define=ENV=production
/// ```
///
/// OWASP references:
/// - A02:2021 Cryptographic Failures (no hardcoded secrets)
/// - A05:2021 Security Misconfiguration (env-based config)
/// - A09:2021 Security Logging (audit key usage)
library;

import 'package:flutter/foundation.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Centralized, secure access to all configuration values.
///
/// All values come from --dart-define at build time.
/// In debug mode, missing values log warnings.
/// In release mode, missing critical values throw errors.
class SecureConfig {
  // ─────────────── Supabase ───────────────

  /// Supabase project URL (e.g., https://abcd1234.supabase.co)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anonymous key (public, but still injected at build time)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // ─────────────── Sentry ───────────────

  /// Sentry DSN for error reporting
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // ─────────────── Gemini AI ───────────────

  /// Gemini API key for AI tutor features
  /// IMPORTANT: This key should have usage quotas set in Google Cloud Console
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // ─────────────── Environment ───────────────

  /// Current environment (development, staging, production)
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Whether running in production
  static bool get isProduction => environment == 'production';

  /// Whether running in development
  static bool get isDevelopment => environment == 'development';

  // ─────────────── Validation ───────────────

  /// Validate that all required secrets are present.
  /// Call this during app initialization.
  ///
  /// In release mode, throws if critical secrets are missing.
  /// In debug mode, logs warnings for missing secrets.
  static void validateConfiguration() {
    final missing = <String>[];

    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');

    // Non-critical but recommended
    if (sentryDsn.isEmpty) {
      AppLogger.warning('SENTRY_DSN not configured — error reporting disabled');
    }
    if (geminiApiKey.isEmpty) {
      AppLogger.warning('GEMINI_API_KEY not configured — AI features disabled');
    }

    if (missing.isNotEmpty) {
      final message =
          'Missing required configuration: ${missing.join(', ')}. '
          'Provide via --dart-define at build time.';

      if (kReleaseMode) {
        // OWASP A05: Fail securely — do not start without config
        throw StateError('CRITICAL: $message');
      } else {
        // In debug, warn but allow startup for local development
        AppLogger.warning(message);
      }
    } else {
      AppLogger.info('SecureConfig: All required configuration present [env: $environment]');
    }
  }

  // ─────────────── Safety Guards ───────────────

  /// Check that a specific key is available before using it.
  /// Returns true if the key has a value.
  static bool hasKey(String keyName) {
    switch (keyName) {
      case 'SUPABASE_URL': return supabaseUrl.isNotEmpty;
      case 'SUPABASE_ANON_KEY': return supabaseAnonKey.isNotEmpty;
      case 'SENTRY_DSN': return sentryDsn.isNotEmpty;
      case 'GEMINI_API_KEY': return geminiApiKey.isNotEmpty;
      default: return false;
    }
  }

  /// Mask a key for safe logging (shows first 4 chars + ***).
  /// NEVER log full API keys.
  static String maskKey(String key) {
    if (key.isEmpty) return '(empty)';
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}****${key.substring(key.length - 4)}';
  }

  /// Private constructor — this is a static utility class.
  SecureConfig._();
}
