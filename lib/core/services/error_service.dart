import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for error service
final errorServiceProvider = Provider<ErrorService>((ref) {
  return ErrorService(ref);
});

/// Provider for error state management
final errorStateProvider =
    StateNotifierProvider<ErrorStateNotifier, ErrorState>((ref) {
  return ErrorStateNotifier();
});

/// Service for managing error states and error UI across the app
/// Service for converting raw exceptions into user-friendly error messages.
class ErrorService {
  /// The [Ref] used to access other providers.
  final Ref ref;

  /// Creates an [ErrorService].
  ErrorService(this.ref);

  /// Handles common auth errors
  String getAuthErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('password') && message.contains('weak')) {
      return 'Password must be at least 8 characters with uppercase, lowercase, and numbers.';
    }
    if (message.contains('already exists') || message.contains('taken')) {
      return 'This email is already registered.';
    }
    if (message.contains('invalid') || message.contains('credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('too many')) {
      return 'Too many login attempts. Please try again later.';
    }
    return 'An authentication error occurred. Please try again.';
  }

  /// Handles common database errors
  String getDatabaseErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network') || message.contains('connection')) {
      return 'Network connection failed. Please check your internet.';
    }
    if (message.contains('auth') || message.contains('unauthorized')) {
      return 'You are not authorized to perform this action.';
    }
    if (message.contains('not found')) {
      return 'The requested item was not found.';
    }
    if (message.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    }
    return 'An error occurred while accessing the database. Please try again.';
  }

  /// Generic error message formatter
  String getErrorMessage(Object error, {String? context}) {
    if (context == 'auth') {
      return getAuthErrorMessage(error);
    }
    if (context == 'database') {
      return getDatabaseErrorMessage(error);
    }
    if (context == 'validation') {
      return getValidationErrorMessage(error);
    }

    // Default: try to detect error type
    final message = error.toString().toLowerCase();
    if (message.contains('auth')) return getAuthErrorMessage(error);
    if (message.contains('database') || message.contains('query')) {
      return getDatabaseErrorMessage(error);
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Handles common validation errors
  String getValidationErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('empty')) {
      return 'This field cannot be empty.';
    }
    if (message.contains('length')) {
      return 'Please check the length of your input.';
    }
    if (message.contains('format')) {
      return 'The input format is invalid.';
    }
    return 'Please check your input and try again.';
  }

  /// Logs an error with optional context and stack trace.
  void logError(String message, Object error, [StackTrace? stackTrace]) {
    AppLogger.error('$message: $error', error: error, stackTrace: stackTrace);
    // Optionally trigger a state update to show a snackbar or alert
    ref.read(errorStateProvider.notifier).setError(
          title: 'Error',
          message: message,
          details: error.toString(),
        );
  }
}

/// State provider for tracking current error
/// Immutable state representing the current error context of the application.
class ErrorState {
  /// The brief title for the error.
  final String? title;

  /// The main user-facing error message.
  final String? message;

  /// Optional technical details or stack trace info.
  final String? details;

  /// The point in time when the error was recorded.
  final DateTime? timestamp;

  /// Creates an [ErrorState].
  ErrorState({
    this.title,
    this.message,
    this.details,
    this.timestamp,
  });

  /// Whether an error is currently present in the state.
  bool get hasError => message != null;

  /// Clear error state
  ErrorState clear() {
    return ErrorState();
  }

  /// Creates a copy of this state with the provided fields replaced.
  ErrorState copyWith({
    String? title,
    String? message,
    String? details,
    DateTime? timestamp,
  }) {
    return ErrorState(
      title: title ?? this.title,
      message: message ?? this.message,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Notifier that manages the global [ErrorState].
/// Notifier that manages the global error state.
class ErrorStateNotifier extends StateNotifier<ErrorState> {
  /// Creates an [ErrorStateNotifier] with an initial empty state.
  ErrorStateNotifier() : super(ErrorState());

  /// Clear the error
  void clear() {
    state = state.clear();
  }

  /// Set an error
  void setError({
    required String title,
    required String message,
    String? details,
  }) {
    state = ErrorState(
      title: title,
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }

  /// Clear error after delay (useful for snackbars)
  void setErrorWithAutoClear({
    required String title,
    required String message,
    String? details,
    Duration clearDelay = const Duration(seconds: 5),
  }) {
    setError(
      title: title,
      message: message,
      details: details,
    );

    Future.delayed(clearDelay, () {
      if (state.timestamp?.add(clearDelay).isBefore(DateTime.now()) ?? false) {
        clear();
      }
    });
  }
}
