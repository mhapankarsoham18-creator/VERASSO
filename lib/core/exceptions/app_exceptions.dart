/// Exception thrown when authentication or authorization fails.
class AppAuthException extends AppException {
  /// Creates an [AppAuthException].
  const AppAuthException([super.message = 'Authentication failed', super.code]);
}

/// Custom exception classes for Verasso app
/// Base class for all custom exceptions in the Verasso application.
class AppException implements Exception {
  /// A user-friendly message describing the error.
  final String message;

  /// An optional error code for machine-level handling.
  final String? code;

  /// The underlying original error if this exception wraps another.
  final dynamic originalError;

  /// Creates an [AppException].
  const AppException(this.message, [this.code, this.originalError]);

  @override
  String toString() =>
      'AppException: $message ${code != null ? '[$code]' : ''}';
}

/// Exception thrown when a database or Supabase operation fails.
class DatabaseException extends AppException {
  /// Creates a [DatabaseException].
  const DatabaseException(
      [super.message = 'Database operation failed',
      super.code,
      super.originalError]);
}

/// Exception thrown when an error occurs within the mesh network.
class MeshException extends AppException {
  /// Creates a [MeshException].
  const MeshException([super.message = 'Mesh network error']);
}

/// Exception thrown when a network-related failure occurs.
class NetworkException extends AppException {
  /// Creates a [NetworkException].
  const NetworkException(
      [super.message = 'Network connection error', super.code]);
}

/// Exception thrown when data validation fails.
class ValidationException extends AppException {
  /// Creates a [ValidationException].
  const ValidationException([super.message = 'Validation failed']);
}
