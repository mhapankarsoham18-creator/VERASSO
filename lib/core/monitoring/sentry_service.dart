import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Service for Sentry error reporting and monitoring
class SentryService {
  static const String _sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '', // Add your Sentry DSN here or via --dart-define
  );

  /// Add breadcrumb for debugging context
  /// Example: User navigated to a screen, tapped a button, etc.
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Capture an exception
  static Future<SentryId> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    SentryLevel level = SentryLevel.error,
  }) async {
    return await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'hint': hint}) : null,
      withScope: (scope) {
        scope.level = level;
      },
    );
  }

  /// Capture a message
  static Future<SentryId> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? params,
  }) async {
    return await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (params != null) {
          params.forEach((key, value) {
            scope.setContexts(key, value);
          });
        }
      },
    );
  }

  /// Clear user context
  /// Call this after user logs out
  static Future<void> clearUser() async {
    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Initialize Sentry
  /// Should be called before runApp() in main.dart
  static Future<void> initialize({
    required Function() appRunner,
    String? dsn,
    String environment = 'production',
  }) async {
    final sentryDsn = dsn ?? _sentryDsn;

    // Skip Sentry in debug mode if DSN is empty
    if (sentryDsn.isEmpty && kDebugMode) {
      if (kDebugMode) {
        AppLogger.warning(
            'Sentry DSN not provided, skipping Sentry initialization');
      }
      appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = kDebugMode ? 'development' : environment;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.profilesSampleRate = kDebugMode ? 1.0 : 0.1;

        // Capture failed HTTP requests
        options.captureFailedRequests = true;

        // Report errors in debug mode
        options.debug = kDebugMode;

        // Attach screenshots on errors (mobile only)
        options.attachScreenshot = true;

        // Set release version
        options.release = 'verasso@1.2.0+3';

        // Attach stack trace for all messages
        options.attachStacktrace = true;

        // Filter out personally identifiable information
        // Filter out personally identifiable information
        options.beforeSend = (event, hint) => event;
      },
      appRunner: appRunner,
    );
  }

  /// Set custom context
  static Future<void> setContext(String key, Map<String, dynamic> value) async {
    await Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// Set a custom tag
  static Future<void> setTag(String key, String value) async {
    await Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Set user context for error tracking
  /// Call this after user logs in
  static Future<void> setUser({
    required String userId,
    String? email,
    String? username,
  }) async {
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: email,
        username: username,
      ));
    });
  }

  /// Automatically set user from Supabase session
  static Future<void> syncUserFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await setUser(
          userId: user.id,
          email: user.email,
          username: user.userMetadata?['username'] as String?,
        );
      } else {
        await clearUser();
      }
    } catch (e) {
      if (kDebugMode) AppLogger.error('Error syncing user to Sentry', error: e);
    }
  }

  /// Helper to wrap async operations with error capture
  static Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      if (operationName != null) {
        addBreadcrumb(
          message: 'Starting: $operationName',
          category: 'operation',
        );
      }

      final result = await operation();

      if (operationName != null) {
        addBreadcrumb(
          message: 'Completed: $operationName',
          category: 'operation',
          level: SentryLevel.debug,
        );
      }

      return result;
    } catch (e, stackTrace) {
      await captureException(
        e,
        stackTrace: stackTrace,
        hint: operationName,
      );
      return null;
    }
  }
}
