/// Typed exceptions for Verasso.
/// Replace all `throw Exception('string')` with these.
library;

class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// User is not logged in or session expired.
class AppAuthException extends AppException {
  AppAuthException([super.message = 'Not authenticated']);
}

/// Server or network is unreachable.
class NetworkException extends AppException {
  NetworkException([super.message = 'Network unreachable', super.originalError]);
}

/// Input validation failed (e.g. message too long, invalid username).
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// RLS or authorization denied the operation.
class PermissionException extends AppException {
  PermissionException([super.message = 'Permission denied']);
}

/// A required resource was not found (e.g. profile, post).
class NotFoundException extends AppException {
  NotFoundException([super.message = 'Resource not found']);
}
