import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/validators/input_validator.dart';

void main() {
  group('InputValidator', () {
    group('sanitize', () {
      test('returns empty string for empty input', () {
        expect(InputValidator.sanitize(''), '');
      });

      test('escapes HTML angle brackets', () {
        final result = InputValidator.sanitize('<script>alert("xss")</script>');
        expect(result.contains('<script>'), false);
        expect(result.contains('</script>'), false);
      });

      test('blocks javascript: URIs', () {
        final result = InputValidator.sanitize('javascript:alert(1)');
        expect(result.contains('javascript:'), false);
        expect(result.contains('blocked:'), true);
      });

      test('blocks vbscript: URIs', () {
        final result = InputValidator.sanitize('vbscript:alert(1)');
        expect(result.contains('vbscript:'), false);
      });

      test('preserves normal text', () {
        expect(InputValidator.sanitize('Hello World'), 'Hello World');
      });

      test('trims whitespace', () {
        expect(InputValidator.sanitize('  hello  '), 'hello');
      });
    });

    group('validatePost', () {
      test('returns error for empty content', () {
        expect(InputValidator.validatePost(''), isNotNull);
        expect(InputValidator.validatePost('   '), isNotNull);
      });

      test('returns null for valid content', () {
        expect(InputValidator.validatePost('Hello world!'), isNull);
      });

      test('returns error for content exceeding 500 characters', () {
        final longText = 'a' * 501;
        expect(InputValidator.validatePost(longText), isNotNull);
      });

      test('returns null for content at exactly 500 characters', () {
        final exactText = 'a' * 500;
        expect(InputValidator.validatePost(exactText), isNull);
      });
    });

    group('validateUsername', () {
      test('returns error for empty username', () {
        expect(InputValidator.validateUsername(''), isNotNull);
      });

      test('returns error for username under 3 characters', () {
        expect(InputValidator.validateUsername('ab'), isNotNull);
      });

      test('returns error for username over 20 characters', () {
        expect(InputValidator.validateUsername('a' * 21), isNotNull);
      });

      test('returns error for uppercase letters', () {
        expect(InputValidator.validateUsername('HelloWorld'), isNotNull);
      });

      test('returns error for special characters', () {
        expect(InputValidator.validateUsername('hello@world'), isNotNull);
        expect(InputValidator.validateUsername('hello world'), isNotNull);
      });

      test('accepts valid usernames', () {
        expect(InputValidator.validateUsername('hello_world'), isNull);
        expect(InputValidator.validateUsername('user123'), isNull);
        expect(InputValidator.validateUsername('abc'), isNull);
      });
    });

    group('validateDisplayName', () {
      test('returns error for empty display name', () {
        expect(InputValidator.validateDisplayName(''), isNotNull);
        expect(InputValidator.validateDisplayName('   '), isNotNull);
      });

      test('returns error for display name over 40 characters', () {
        expect(InputValidator.validateDisplayName('a' * 41), isNotNull);
      });

      test('returns null for valid display name', () {
        expect(InputValidator.validateDisplayName('Soham M'), isNull);
      });
    });

    group('validateSecureMessage', () {
      test('returns error for empty message', () {
        expect(InputValidator.validateSecureMessage(''), isNotNull);
        expect(InputValidator.validateSecureMessage('   '), isNotNull);
      });

      test('returns error for message exceeding 2048 bytes', () {
        final longMessage = 'a' * 2049;
        expect(InputValidator.validateSecureMessage(longMessage), isNotNull);
      });

      test('returns null for valid message', () {
        expect(InputValidator.validateSecureMessage('Hello'), isNull);
      });
    });

    group('validateComment', () {
      test('returns error for empty comment', () {
        expect(InputValidator.validateComment(''), isNotNull);
      });

      test('returns error for comment exceeding 280 characters', () {
        expect(InputValidator.validateComment('a' * 281), isNotNull);
      });

      test('returns null for valid comment', () {
        expect(InputValidator.validateComment('Great post!'), isNull);
      });
    });
  });
}
