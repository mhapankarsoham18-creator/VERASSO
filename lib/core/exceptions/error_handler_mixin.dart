import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Mixin to provide standardized error handling capabilities to repositories and services.
mixin ErrorHandlerMixin {
  /// Execute an operation with standardized error handling.
  ///
  /// [operation]: The async function to execute.
  /// [context]: A string description of the operation context (e.g., 'AuthRepository.signIn').
  /// [userMessage]: Optional user-facing error message to return/throw if things go wrong.
  /// [reportToSentry]: Whether to report this error to Sentry (default: false).
  /// [rethrowError]: Whether to rethrow the error after logging (default: true).
  Future<T?> handleError<T>({
    required Future<T> Function() operation,
    required String context,
    String? userMessage,
    bool reportToSentry = false,
    bool rethrowError = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      // 1. Log locally
      AppLogger.error('Error in $context', error: e, stackTrace: stackTrace);

      // 2. Report to Sentry if critical
      if (reportToSentry) {
        SentryService.captureException(e, stackTrace: stackTrace);
      }

      // 3. Rethrow if requested
      if (rethrowError) {
        rethrow; // Preserves original exception type
      }

      return null;
    }
  }

  /// Helper to record an error without throwing
  void logError(dynamic error, StackTrace? stackTrace, String context,
      {bool critical = false}) {
    AppLogger.error('Error in $context', error: error, stackTrace: stackTrace);
    if (critical) {
      SentryService.captureException(error, stackTrace: stackTrace);
    }
  }
}
