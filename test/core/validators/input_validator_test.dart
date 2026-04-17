import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/validators/input_validator.dart';

void main() {
  group('InputValidator Tests', () {
    test('sanitize removes script tags', () {
      const input = '<script>alert("XSS")</script>Hello World';
      final output = InputValidator.sanitize(input);
      expect(output, '&lt;script&gt;alert("XSS")&lt;/script&gt;Hello World');
    });

    test('sanitize handles empty string', () {
      expect(InputValidator.sanitize(''), '');
    });

    test('validatePost checks length limits', () {
      final longPost = List.filled(501, 'a').join();
      expect(InputValidator.validatePost(longPost), 'Content exceeds maximum length of 500 characters.');
      expect(InputValidator.validatePost('A valid post'), isNull);
    });

    test('validateUsername enforces constraints', () {
      expect(InputValidator.validateUsername('ab'), 'Username must be at least 3 characters.');
      expect(InputValidator.validateUsername('Valid_123'), 'Username can only contain lowercase letters, numbers, and underscores.');
      expect(InputValidator.validateUsername('valid_123'), isNull);
    });

    test('validateSecureMessage limits to 2048 bytes', () {
      final longMsg = List.filled(2049, 'a').join();
      expect(InputValidator.validateSecureMessage(longMsg), 'Message payload is too large (> 2048 bytes).');
      expect(InputValidator.validateSecureMessage('Valid secure text'), isNull);
    });

    test('validateComment limits to 280 chars', () {
      final longComment = List.filled(281, 'a').join();
      expect(InputValidator.validateComment(longComment), 'Comment exceeds 280 characters limit.');
      expect(InputValidator.validateComment('Valid comment'), isNull);
      expect(InputValidator.validateComment('   '), 'Comment cannot be empty.');
    });
  });
}
