class PasswordValidator {
  /// Validates a password based on strong criteria.
  /// Minimum 8 characters, at least one uppercase letter, one lowercase letter,
  /// one number and one special character.
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#\$&*~%]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$&*~%)';
    }
    return null; // Password is valid
  }
}
