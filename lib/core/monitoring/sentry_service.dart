import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Service for Sentry error reporting and monitoring.
/// All secrets are passed via --dart-define at build time.
class SentryService {
  static const String _sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Initialize Sentry. Should be called before runApp() in main.dart.
  static Future<void> initialize({
    required FutureOr<void> Function() appRunner,
    String? environment,
  }) async {
    if (_sentryDsn.isEmpty) {
      AppLogger.info('Sentry DSN not configured. Running without Sentry.');
      await appRunner();
      return;
    }

    try {
      await SentryFlutter.init((options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.environment =
            environment ?? (kDebugMode ? 'development' : 'production');
        options.enableAutoPerformanceTracing = true;
        options.sendDefaultPii = false;
        options.attachStacktrace = true;
        options.attachScreenshot = true;
        options.debug = kDebugMode;
        options.release = 'verasso@1.2.0+3';
        options.beforeSend = (event, hint) => event;
      }, appRunner: appRunner);
      AppLogger.info('Sentry initialized [env: $environment]');
    } catch (e) {
      AppLogger.error('Failed to initialize Sentry', error: e);
      await appRunner();
    }
  }

  /// Add breadcrumb for debugging context.
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

  /// Capture an exception and send to Sentry.
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

  /// Capture a message.
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

  /// Set user context for error tracking.
  static Future<void> setUser({
    required String userId,
    String? email,
    String? username,
  }) async {
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: userId, email: email, username: username));
    });
  }

  /// Clear user context (e.g. on logout).
  static Future<void> clearUser() async {
    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Sync user from current Supabase session to Sentry.
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

  /// Set custom context.
  static Future<void> setContext(String key, Map<String, dynamic> value) async {
    await Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// Set a custom tag.
  static Future<void> setTag(String key, String value) async {
    await Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }
}
