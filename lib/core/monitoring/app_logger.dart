import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'sentry_service.dart';

/// Centralized logging service for the app
/// Replaces print() statements with proper structured logging
/// Logs to console in debug mode and to Sentry for monitoring
class AppLogger {
  /// Log debug information (only in debug mode)
  /// Used for detailed technical information
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
      if (error != null) {
        debugPrint('[DEBUG] Error: $error');
      }
    }

    // Always send to Sentry as breadcrumb for context
    SentryService.addBreadcrumb(
      message: message,
      category: 'debug',
      level: SentryLevel.debug,
    );
  }

  /// Log info messages
  /// Used for general informational updates
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }

    SentryService.addBreadcrumb(
      message: message,
      category: 'info',
      level: SentryLevel.info,
    );
  }

  /// Log warning messages
  /// Used for potentially problematic situations
  static void warning(String message, {Object? error}) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
      if (error != null) {
        debugPrint('[WARNING] Error: $error');
      }
    }

    SentryService.addBreadcrumb(
      message: message,
      category: 'warning',
      level: SentryLevel.warning,
    );
  }

  /// Log error messages (sent to Sentry)
  /// Used for unexpected errors that may impact functionality
  /// IMPORTANT: These are sent to Sentry for monitoring
  static void error(
    String message, {
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      debugPrint('[ERROR] Exception: $error');
      if (stackTrace != null) {
        debugPrint('[ERROR] Stack Trace:\n$stackTrace');
      }
    }

    // Send to Sentry for monitoring
    SentryService.captureException(
      error,
      stackTrace: stackTrace ?? StackTrace.current,
      hint: message,
    );
  }

  /// Log critical errors (security, auth, etc)
  /// Should always be sent to Sentry and logged
  static void critical(
    String message, {
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[CRITICAL] $message');
      debugPrint('[CRITICAL] Exception: $error');
    }

    SentryService.captureException(
      error,
      stackTrace: stackTrace ?? StackTrace.current,
      hint: '[CRITICAL] $message',
    );
  }
}
