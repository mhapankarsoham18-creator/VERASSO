import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'sentry_service.dart';

/// Centralized logging service for the app
/// Replaces print() statements with proper structured logging
/// Logs to console in debug mode and to Sentry for monitoring
class AppLogger {
  static bool suppressLogs = Platform.environment.containsKey('FLUTTER_TEST');

  static void _logToConsole(String message) {
    if (kDebugMode && !suppressLogs) {
      debugPrint(message);
    }
  }

  /// Log debug information (only in debug mode)
  /// Used for detailed technical information
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logToConsole('[DEBUG] $message');
    if (error != null) {
      _logToConsole('[DEBUG] Error: $error');
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
    _logToConsole('[INFO] $message');

    SentryService.addBreadcrumb(
      message: message,
      category: 'info',
      level: SentryLevel.info,
    );
  }

  /// Log warning messages
  /// Used for potentially problematic situations
  static void warning(String message, {Object? error}) {
    _logToConsole('[WARNING] $message');
    if (error != null) {
      _logToConsole('[WARNING] Error: $error');
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
    _logToConsole('[ERROR] $message');
    _logToConsole('[ERROR] Exception: $error');
    if (stackTrace != null) {
      _logToConsole('[ERROR] Stack Trace:\n$stackTrace');
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
    _logToConsole('[CRITICAL] $message');
    _logToConsole('[CRITICAL] Exception: $error');

    SentryService.captureException(
      error,
      stackTrace: stackTrace ?? StackTrace.current,
      hint: '[CRITICAL] $message',
    );
  }
}
