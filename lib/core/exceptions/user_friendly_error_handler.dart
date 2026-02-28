import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_exceptions.dart';

/// Converts raw exceptions into user-friendly messages
/// Ensures users see helpful messages while team debugs real errors
class UserFriendlyErrorHandler {
  /// Get a user-friendly display message for any exception
  static String getDisplayMessage(Object? error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Handle rate limiting
    if (error is AppAuthException && error.message.contains('Too many')) {
      return error.message; // Already user-friendly
    }

    // Handle validation errors
    if (error is ValidationException) {
      return error.message;
    }

    // Handle app exceptions
    if (error is AppAuthException) {
      if (error.message.contains('Sign up failed') ||
          error.message.contains('sign up')) {
        return 'Unable to create account. Please try again.';
      }
      if (error.message.contains('Sign in failed') ||
          error.message.contains('sign in')) {
        return 'Authentication failed. Please check your credentials.';
      }
      return 'Authentication failed. Please try again.';
    }

    if (error is NetworkException) {
      return 'No internet connection. Please check your network.';
    }

    if (error is DatabaseException) {
      return 'A database error occurred. Please try again.';
    }

    // Handle Supabase-specific exceptions
    if (error is AuthException) {
      if (error.statusCode == '400') {
        // Check message content for specific cases
        if (error.message.contains('already registered') ||
            error.message.contains('already exists') ||
            error.message.contains('duplicate')) {
          return 'This email is already registered.';
        }
        if (error.message.contains('Invalid') ||
            error.message.contains('invalid')) {
          return 'Invalid credentials. Please check and try again.';
        }
        return 'Invalid request. Please try again.';
      }
      if (error.statusCode == '401' || error.statusCode == '403') {
        return 'Access denied. Please try logging in again.';
      }
      return 'Authentication failed. Please try again.';
    }

    if (error is PostgrestException) {
      // Duplicate key error
      if (error.code == '23505') {
        if (error.message.contains('email')) {
          return 'This email is already registered.';
        }
        if (error.message.contains('username')) {
          return 'This username is already taken.';
        }
        return 'This data already exists.';
      }
      // Foreign key error
      if (error.code == '23503') {
        return 'Invalid reference. Please try again.';
      }
      // Unique constraint error
      if (error.code == '23505') {
        return 'This data already exists.';
      }
      // Generic database error
      return 'A database error occurred. Please try again.';
    }

    // Handle socket exceptions (network errors)
    if (error.toString().contains('Socket') ||
        error.toString().contains('socket')) {
      return 'Network connection error. Please check your internet.';
    }

    // Handle timeout errors
    if (error.toString().contains('timeout') ||
        error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    // Handle string errors (fallback)
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorString.contains('failed')) {
      return 'Operation failed. Please try again.';
    }

    // Default message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get a brief error code/identifier for logging
  static String getErrorCode(Object? error) {
    if (error == null) return 'UNKNOWN';

    if (error is AppAuthException) return 'AUTH_ERROR';
    if (error is NetworkException) return 'NETWORK_ERROR';
    if (error is DatabaseException) return 'DATABASE_ERROR';
    if (error is ValidationException) return 'VALIDATION_ERROR';

    if (error is AuthException) return 'SUPABASE_AUTH_ERROR';
    if (error is PostgrestException) return 'SUPABASE_DB_ERROR';

    return 'UNKNOWN_ERROR';
  }
}
