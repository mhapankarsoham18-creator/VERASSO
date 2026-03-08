import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/input_validator.dart';

void main() {
  group('InputValidator Fuzz Testing (Phase 3.2)', () {
    test('validateText rejects common XSS payloads', () {
      final xssPayloads = [
        '<script>alert("XSS")</script>',
        '<img src=x onerror=alert(1)>',
        'javascript:alert(1)',
        '<svg/onload=alert(1)>',
        '"><script>alert(1)</script>',
        "';alert(1);//",
      ];

      for (final payload in xssPayloads) {
        final result = InputValidator.validateText(payload, fieldName: 'content');
        expect(
          result, 
          contains('invalid characters'), 
          reason: 'Failed to reject XSS payload: $payload',
        );
      }
    });

    test('validateText rejects common SQL injection patterns', () {
      final sqliPayloads = [
        "admin' --",
        "' OR '1'='1",
        "'; DROP TABLE users; --",
        "UNION SELECT password FROM users",
        "1' OR '1' = '1' --",
        "xp_cmdshell('dir')",
      ];

      for (final payload in sqliPayloads) {
        final result = InputValidator.validateText(payload, fieldName: 'content');
        expect(
          result, 
          contains('invalid characters'), 
          reason: 'Failed to reject SQLi payload: $payload',
        );
      }
    });

    test('sanitize removes null bytes and escapes HTML', () {
      const input = 'Hello <script>World</script>\x00 & "Test"';
      final sanitized = InputValidator.sanitize(input);

      // Should remove null byte
      expect(sanitized, isNot(contains('\x00')));
      
      // Should escape HTML
      expect(sanitized, contains('&lt;script&gt;'));
      expect(sanitized, contains('&amp;'));
      expect(sanitized, contains('&quot;'));
      
      // Final outcome check
      expect(sanitized, 'Hello &lt;script&gt;World&lt;/script&gt; &amp; &quot;Test&quot;');
    });

    test('sanitizeForQuery removes SQL comment markers', () {
      const input = 'admin; -- DROP TABLE users; /* test */';
      final sanitized = InputValidator.sanitizeForQuery(input);

      expect(sanitized, isNot(contains('--')));
      expect(sanitized, isNot(contains(';')));
      expect(sanitized, isNot(contains('/*')));
      expect(sanitized, isNot(contains('*/')));
    });

    test('validateEmail rejects invalid formats and lengths', () {
      expect(InputValidator.validateEmail('not-an-email'), isNotNull);
      expect(InputValidator.validateEmail('test@'), isNotNull);
      expect(InputValidator.validateEmail('test@domain'), isNotNull);
      expect(InputValidator.validateEmail('a' * 300 + '@test.com'), contains('too long'));
    });

    test('validatePassword enforces complexity (OWASP)', () {
      expect(InputValidator.validatePassword('short'), contains('at least 8'));
      expect(InputValidator.validatePassword('alllowercase'), contains('uppercase letter'));
      expect(InputValidator.validatePassword('ALLUPPERCASE'), contains('lowercase letter'));
      expect(InputValidator.validatePassword('NoNumberCase'), contains('number'));
      expect(InputValidator.validatePassword('ValidPass123'), isNull);
    });

    test('validateSchema prevents Mass Assignment (unexpected fields)', () {
      final data = {
        'username': 'valid_user',
        'isAdmin': true, // Malicious field
      };

      final schema = {
        'username': const SchemaField(type: String, required: true),
      };

      final errors = InputValidator.validateSchema(data: data, schema: schema);
      expect(errors.containsKey('isAdmin'), isTrue);
      expect(errors['isAdmin'], contains('Unexpected field'));
    });
  });
}
