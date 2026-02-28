/// Input validation service for form fields
library;

import '../../l10n/app_localizations.dart';

/// utility class for validating user input fields like email, password, etc.
class InputValidator {
  /// Get password strength indicator (0-4)
  /// 0 = weak, 1 = fair, 2 = good, 3 = strong, 4 = very strong
  int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) score++;

    // Check for special characters
    final specialCharRegex = RegExp(r'[!@#$%^&*()_+=\-\[\]{};:,.<>?/\\|`~]');
    if (specialCharRegex.hasMatch(password)) {
      score++;
    }

    return score > 4 ? 4 : score;
  }

  /// Check if input matches a phone number pattern
  (bool, String?) validatePhoneNumber(String phone) {
    final trimmed = phone.trim();

    if (trimmed.isEmpty) {
      return (false, 'Phone number is required');
    }

    // Basic international phone format (at least 7 digits)
    final phoneRegex = RegExp(r'^[\d\s+\-()]+$');

    if (!phoneRegex.hasMatch(trimmed)) {
      return (false, 'Please enter a valid phone number');
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7) {
      return (false, 'Phone number must have at least 7 digits');
    }

    return (true, null);
  }

  /// Validates an email address.
  static (bool, String?) validateEmail(String email, AppLocalizations l10n) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return (false, l10n.emailRequired);
    }
    if (trimmed.length > 254) {
      return (false, l10n.emailTooLong);
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return (false, l10n.invalidEmail);
    }
    return (true, null);
  }

  /// Validates field length boundaries.
  static (bool, String?) validateLength(String value, String fieldName,
      int minLength, int maxLength, AppLocalizations l10n) {
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return (false, l10n.fieldTooShort(fieldName, minLength.toString()));
    }
    if (trimmed.length > maxLength) {
      return (false, l10n.fieldTooLong(fieldName, maxLength.toString()));
    }
    return (true, null);
  }

  /// Validates a full name.
  static (bool, String?) validateName(String name, AppLocalizations l10n) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return (false, l10n.nameRequired);
    }
    if (trimmed.length < 2) {
      return (false, l10n.nameTooShort);
    }
    if (trimmed.length > 50) {
      return (false, l10n.nameTooLong);
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s\-]+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return (false, l10n.nameInvalidChars);
    }
    return (true, null);
  }

  /// Validates a password's complexity.
  static (bool, String?) validatePassword(
      String password, AppLocalizations l10n) {
    if (password.isEmpty) {
      return (false, l10n.passwordRequired);
    }
    if (password.length < 8) {
      return (false, l10n.passwordTooShort);
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return (false, l10n.passwordNoUppercase);
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return (false, l10n.passwordNoLowercase);
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return (false, l10n.passwordNoNumber);
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return (false, l10n.passwordNoSpecial);
    }
    return (true, null);
  }

  /// Checks if two password strings match.
  static (bool, String?) validatePasswordConfirmation(
      String password, String confirmation, AppLocalizations l10n) {
    if (confirmation.isEmpty) {
      return (false, l10n.confirmPasswordRequired);
    }
    if (password != confirmation) {
      return (false, l10n.passwordsDoNotMatch);
    }
    return (true, null);
  }

  /// Validates a phone number (basic check).
  static (bool, String?) validatePhone(String phone, AppLocalizations l10n) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      return (false, l10n.phoneRequired);
    }
    // Very basic regex for international or local formats
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return (false, l10n.invalidPhone);
    }
    if (trimmed.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      return (false, l10n.phoneTooShort);
    }
    return (true, null);
  }

  /// Validates a generic required field.
  static (bool, String?) validateRequired(
      String? value, String fieldName, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return (false, l10n.fieldRequired(fieldName));
    }
    return (true, null);
  }

  /// Validates a username.
  static (bool, String?) validateUsername(
      String username, AppLocalizations l10n) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return (false, l10n.usernameRequired);
    }
    if (trimmed.length < 3) {
      return (false, l10n.usernameTooShort);
    }
    if (trimmed.length > 20) {
      return (false, l10n.usernameTooLong);
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return (false, l10n.usernameInvalidChars);
    }
    return (true, null);
  }
}
