import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/shield_service.dart';

void main() {
  late ShieldService shieldService;

  setUp(() {
    shieldService = ShieldService();
  });

  group('ShieldService Tests', () {
    test('scrambleText maintains length and character count (excluding spaces)',
        () {
      const input = 'Hello World';
      final scrambled = shieldService.scrambleText(input);

      expect(scrambled.length, equals(input.length));
      expect(scrambled, isNot(equals(input)));
    });

    test('scrambleText returns empty string for empty input', () {
      expect(shieldService.scrambleText(''), equals(''));
    });

    test('encryptPayload and decryptPayload are consistent', () {
      const plainText = 'highly secret data';
      final encrypted = shieldService.encryptPayload(plainText);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainText)));

      final decrypted = shieldService.decryptPayload(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('decryptPayload returns error marker on invalid input', () {
      final decrypted = shieldService.decryptPayload('invalid-base64-or-data');
      expect(decrypted, contains('Decryption Failed'));
    });

    test('rotateSessionKeys makes previous data unreadable', () {
      const plainText = 'session secret';
      final encrypted = shieldService.encryptPayload(plainText);

      shieldService.rotateSessionKeys();

      final decrypted = shieldService.decryptPayload(encrypted);
      expect(decrypted, isNot(equals(plainText)));
      expect(decrypted, contains('Decryption Failed'));
    });
  });
}
