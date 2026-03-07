/// OWASP-compliant input validation and sanitization.
///
/// Provides schema-based validation with type checks, length limits,
/// and rejection of unexpected fields. All user inputs should pass
/// through these validators before being processed.
///
/// Best practices implemented:
/// - Whitelist-based validation (only allow known-good input)
/// - Length limits on all string fields
/// - Type enforcement (reject wrong types)
/// - HTML/script injection prevention
/// - SQL injection character filtering
/// - Reject unexpected/extra fields in structured data
library;

/// Validates and sanitizes user input following OWASP guidelines.
class InputValidator {
  // ─────────────── Length Limits (OWASP A03:2021 Injection) ───────────────

  /// Max lengths for common fields — prevents buffer overflow and DoS
  static const Map<String, int> fieldMaxLengths = {
    'email': 254, // RFC 5321
    'password': 128, // Generous but bounded
    'username': 30, // Display name
    'displayName': 50,
    'bio': 500,
    'title': 200,
    'content': 10000, // Post/comment body
    'message': 2000, // Chat messages
    'code': 5000, // Code challenge answers
    'searchQuery': 100,
    'inviteCode': 36, // UUID format
    'feedbackText': 2000,
    'url': 2048, // RFC 2616
  };

  // ─────────────── Regex Patterns ───────────────

  /// Email: RFC 5322 simplified
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Username: alphanumeric + underscore, 3-30 chars
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  /// UUID format (for IDs, invite codes)
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Dangerous patterns that indicate injection attacks
  static final RegExp _dangerousPatterns = RegExp(
    r'(<script|javascript:|on\w+=|eval\(|exec\(|union\s+select|drop\s+table|insert\s+into|delete\s+from|update\s+.*set|;\s*--|\/\*|\*\/)',
    caseSensitive: false,
  );

  // ─────────────── Validation Methods ───────────────

  /// Validate an email address.
  /// Returns null if valid, error message if invalid.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmed = value.trim().toLowerCase();

    if (trimmed.length > fieldMaxLengths['email']!) {
      return 'Email is too long (max ${fieldMaxLengths['email']} characters)';
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  /// Validate a password.
  /// Enforces OWASP password requirements.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > fieldMaxLengths['password']!) {
      return 'Password is too long (max ${fieldMaxLengths['password']} characters)';
    }

    // OWASP: Check for at least one uppercase, one lowercase, one digit
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null; // Valid
  }

  /// Validate a username.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (trimmed.length > fieldMaxLengths['username']!) {
      return 'Username is too long (max ${fieldMaxLengths['username']} characters)';
    }

    if (!_usernamePattern.hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null; // Valid
  }

  /// Validate a UUID string (for IDs, invite codes, etc.)
  static String? validateUuid(String? value, {String fieldName = 'ID'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (!_uuidPattern.hasMatch(value.trim())) {
      return 'Invalid $fieldName format';
    }

    return null; // Valid
  }

  /// Validate a generic text field with length limits.
  static String? validateText(
    String? value, {
    required String fieldName,
    int minLength = 0,
    int? maxLength,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) return '$fieldName is required';
      return null; // Optional and empty = valid
    }

    final trimmed = value.trim();
    final limit = maxLength ?? fieldMaxLengths[fieldName] ?? 1000;

    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (trimmed.length > limit) {
      return '$fieldName is too long (max $limit characters)';
    }

    // Check for injection patterns
    if (_dangerousPatterns.hasMatch(trimmed)) {
      return '$fieldName contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate a URL.
  static String? validateUrl(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'URL is required';
      return null;
    }

    final trimmed = value.trim();

    if (trimmed.length > fieldMaxLengths['url']!) {
      return 'URL is too long';
    }

    // Only allow http and https schemes
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }

    try {
      Uri.parse(trimmed);
    } catch (_) {
      return 'Invalid URL format';
    }

    return null; // Valid
  }

  // ─────────────── Sanitization Methods ───────────────

  /// Sanitize a string by removing dangerous characters.
  /// Use AFTER validation, before storage/display.
  static String sanitize(String input) {
    // 1. Trim whitespace
    var sanitized = input.trim();

    // 2. Remove null bytes (OWASP: Null Byte Injection)
    sanitized = sanitized.replaceAll('\x00', '');

    // 3. Encode HTML entities to prevent XSS
    sanitized = _escapeHtml(sanitized);

    return sanitized;
  }

  /// Sanitize for database queries (strips SQL-dangerous chars).
  /// Note: Always use parameterized queries via Supabase — this is defense-in-depth.
  static String sanitizeForQuery(String input) {
    var sanitized = sanitize(input);

    // Remove SQL comment markers
    sanitized = sanitized.replaceAll('--', '');
    sanitized = sanitized.replaceAll('/*', '');
    sanitized = sanitized.replaceAll('*/', '');

    // Remove semicolons (statement terminators)
    sanitized = sanitized.replaceAll(';', '');

    return sanitized;
  }

  /// Escape HTML special characters to prevent XSS.
  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  // ─────────────── Schema Validation ───────────────

  /// Validate a structured data map against a schema.
  ///
  /// Rejects unexpected fields (OWASP: Mass Assignment Prevention).
  /// Example:
  /// ```dart
  /// final errors = InputValidator.validateSchema(
  ///   data: {'email': 'test@test.com', 'password': '123'},
  ///   schema: {
  ///     'email': SchemaField(type: String, required: true, validator: InputValidator.validateEmail),
  ///     'password': SchemaField(type: String, required: true, validator: InputValidator.validatePassword),
  ///   },
  /// );
  /// ```
  static Map<String, String> validateSchema({
    required Map<String, dynamic> data,
    required Map<String, SchemaField> schema,
    bool rejectUnexpectedFields = true,
  }) {
    final errors = <String, String>{};

    // OWASP: Reject unexpected fields to prevent mass assignment
    if (rejectUnexpectedFields) {
      for (final key in data.keys) {
        if (!schema.containsKey(key)) {
          errors[key] = 'Unexpected field: $key';
        }
      }
    }

    // Validate each expected field
    for (final entry in schema.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      final value = data[fieldName];

      // Required check
      if (field.required &&
          (value == null || (value is String && value.trim().isEmpty))) {
        errors[fieldName] = '$fieldName is required';
        continue;
      }

      // Skip if optional and missing
      if (value == null) continue;

      // Type check
      if (field.type != null && value.runtimeType != field.type) {
        errors[fieldName] = '$fieldName must be of type ${field.type}';
        continue;
      }

      // Custom validator
      if (field.validator != null) {
        final error = field.validator!(
          value is String ? value : value.toString(),
        );
        if (error != null) {
          errors[fieldName] = error;
        }
      }
    }

    return errors;
  }
}

/// Defines a field in a validation schema.
class SchemaField {
  /// Expected Dart type (e.g., String, int, bool)
  final Type? type;

  /// Whether the field is required
  final bool required;

  /// Custom validation function (returns null if valid, error message if invalid)
  final String? Function(String?)? validator;

  const SchemaField({this.type, this.required = false, this.validator});
}
