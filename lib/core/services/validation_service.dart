import '../exceptions/app_exceptions.dart';

/// Utility service for validating user input and formatting exceptions.
class ValidationService {
  /// Formats a dynamic exception [e] into a user-friendly error message.
  static String formatException(dynamic e) {
    if (e is AppAuthException) return e.message;
    if (e is ValidationException) return e.message;
    if (e is DatabaseException) return e.message;
    return e.toString().replaceAll('Exception:', '').trim();
  }

  /// Validates a user's biography text.
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Bio is optional
    }

    if (value.length > 500) {
      return 'Bio is too long (max 500 characters)';
    }

    return null;
  }

  /// Validates a comment or post message.
  static String? validateComment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Comment cannot be empty';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Comment cannot be only whitespace';
    }

    if (value.length > 1000) {
      return 'Comment is too long (max 1000 characters)';
    }

    return null;
  }

  /// Validates an email address format.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Enhanced email validation (Standard pattern)
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

    if (value.length > 254) {
      return 'Email is too long (max 254 characters)';
    }

    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a user's full name.
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }

    if (value.length > 100) {
      return 'Full name is too long (max 100 characters)';
    }

    final nameRegex = RegExp(r"^[a-zA-Z\s\-' \.]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Full name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates that a string [value] is between [min] and [max] characters.
  static String? validateLength(
      String? value, int min, int max, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; // Empty check should be handled by validateRequired if needed
    }
    if (value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    if (value.length > max) {
      return '$fieldName must be less than $max characters';
    }
    return null;
  }

  /// Validate login input (email and password)
  static String? validateLogin({
    required String email,
    required String password,
  }) {
    // Check email
    var validation = validateEmail(email);
    if (validation != null) return validation;

    if (password.isEmpty) {
      return 'Password is required';
    }

    return null;
  }

  /// Validates a password against security requirements.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return 'Password is too long (max 128 characters)';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (!value.contains(RegExp(r"[!@#$%^&*()_+=\[\]{};:'" r'",.<>?/\\|-]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }

    return null;
  }

  /// Validates the content of a feed post.
  static String? validatePostContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Post content is required';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Post cannot be only whitespace';
    }

    if (value.length > 5000) {
      return 'Post is too long (max 5000 characters)';
    }

    return null;
  }

  /// Validate registration input (all fields together)
  static String? validateRegistration({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) {
    // Check email
    var validation = validateEmail(email);
    if (validation != null) return validation;

    // Check password
    validation = validatePassword(password);
    if (validation != null) return validation;

    // Check username
    validation = validateUsername(username);
    if (validation != null) return validation;

    // Check full name
    validation = validateFullName(fullName);
    if (validation != null) return validation;

    return null;
  }

  /// Validates that a required [field] is not empty.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates a search query string.
  static String? validateSearchQuery(String? value) {
    if (value == null || value.isEmpty) {
      return 'Search query cannot be empty';
    }

    if (value.trim().isEmpty) {
      return 'Search query cannot be only whitespace';
    }

    if (value.length > 200) {
      return 'Search query is too long (max 200 characters)';
    }

    return null;
  }

  /// Validates that a [value] is a properly formatted URL.
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }

    try {
      Uri.parse(value);
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        return 'URL must start with http:// or https://';
      }
      return null;
    } catch (_) {
      return 'Invalid URL format';
    }
  }

  /// Validates a username for length and allowed characters.
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.length > 20) {
      return 'Username must be at most 20 characters';
    }

    if (!value[0].contains(RegExp(r'[a-zA-Z]'))) {
      return 'Username must start with a letter';
    }

    if (!value.contains(RegExp(r'^[a-zA-Z0-9_]+$'))) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }
}
