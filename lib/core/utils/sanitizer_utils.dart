/// Utility class for sanitizing user inputs to prevent XSS and other injection attacks.
class SanitizerUtils {
  /// Sanitizes a list of strings.
  static List<String> sanitizeList(List<String> inputs) {
    return inputs.map((s) => sanitizeString(s)).toList();
  }

  /// Trims whitespace and removes potentially dangerous HTML characters.
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;

    // Basic HTML escaping
    String sanitized = input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');

    return sanitized.trim();
  }

  /// Removes any non-alphanumeric characters except basic punctuation.
  static String sanitizeUsername(String username) {
    if (username.isEmpty) return username;
    // Allow letters, numbers, underscore, and dot
    return username.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '').trim();
  }
}
