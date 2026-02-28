import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/utils/sanitizer_utils.dart';

void main() {
  group('SanitizerUtils', () {
    test('sanitizeString should escape HTML special characters', () {
      const input = '<script>alert("xss")</script> & more';
      const expected =
          '&lt;script&gt;alert(&quot;xss&quot;)&lt;&#x2F;script&gt; &amp; more';
      expect(SanitizerUtils.sanitizeString(input), expected);
    });

    test('sanitizeString should trim whitespace', () {
      const input = '   hello world   ';
      expect(SanitizerUtils.sanitizeString(input), 'hello world');
    });

    test('sanitizeUsername should remove invalid characters', () {
      const input = 'user@name!123';
      expect(SanitizerUtils.sanitizeUsername(input), 'username123');
    });

    test('sanitizeUsername should allow dots and underscores', () {
      const input = 'user.name_123';
      expect(SanitizerUtils.sanitizeUsername(input), 'user.name_123');
    });

    test('sanitizeList should sanitize all items in the list', () {
      const inputs = ['<p>', '<b>'];
      const expected = ['&lt;p&gt;', '&lt;b&gt;'];
      expect(SanitizerUtils.sanitizeList(inputs), expected);
    });
  });
}
