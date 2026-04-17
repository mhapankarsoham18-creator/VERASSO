import 'dart:convert';

/// Security Hardening Validator
/// 
/// Prevents common attack vectors like XSS injection via markdown/HTML,
/// payload overflows, and enforces structural constraints across the app.
class InputValidator {
  
  /// Sanitizes text by escaping HTML tags and neutralizing basic script injections.
  /// Useful for bio, display names, and comments.
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    
    // Convert problematic characters to HTML entities
    final htmlEscape = HtmlEscape(HtmlEscapeMode.element);
    String sanitized = htmlEscape.convert(input);

    // Remove direct javascript:/vbscript: URI schemes if mapped somehow
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), 'blocked:');
    sanitized = sanitized.replaceAll(RegExp(r'vbscript:', caseSensitive: false), 'blocked:');
    
    // Strip empty HTML nodes often used in markdown exploits if flutter-markdown isn't strict
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    return sanitized.trim();
  }

  /// Validates standard post content (e.g. max 500 characters, no forbidden patterns).
  static String? validatePost(String input) {
    if (input.trim().isEmpty) return 'Content cannot be empty.';
    if (input.length > 500) return 'Content exceeds maximum length of 500 characters.';
    return null;
  }

  /// Validates username (e.g. lowercase, numbers, underscores, max 20 chars).
  static String? validateUsername(String username) {
    if (username.isEmpty) return 'Username is required.';
    if (username.length < 3) return 'Username must be at least 3 characters.';
    if (username.length > 20) return 'Username cannot exceed 20 characters.';
    
    // Only alphanumeric and underscores allowed
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain lowercase letters, numbers, and underscores.';
    }
    return null;
  }

  /// Validates display name
  static String? validateDisplayName(String displayName) {
    if (displayName.trim().isEmpty) return 'Display name is required.';
    if (displayName.length > 40) return 'Display name cannot exceed 40 characters.';
    return null;
  }

  /// Validate secure messaging payload size (Max 2048 bytes after encryption constraints)
  static String? validateSecureMessage(String plaintext) {
    if (plaintext.trim().isEmpty) return 'Message cannot be empty.';
    final byteLength = utf8.encode(plaintext).length;
    if (byteLength > 2048) return 'Message payload is too large (> 2048 bytes).';
    return null;
  }
  
  /// Validate comments
  static String? validateComment(String comment) {
    if (comment.trim().isEmpty) return 'Comment cannot be empty.';
    if (comment.length > 280) return 'Comment exceeds 280 characters limit.';
    return null;
  }
}
