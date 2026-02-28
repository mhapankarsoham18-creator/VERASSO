import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:verasso/core/security/e2e_key_exchange.dart';

void main() {
  group('E2EKeyExchangeService Tests', () {
    late E2EKeyExchangeService keyExchangeService;

    setUp(() {
      keyExchangeService = E2EKeyExchangeService();
    });

    test('generateKeyPair returns valid keys', () {
      final keyPair = keyExchangeService.generateKeyPair();
      expect(keyPair.publicKey, isA<ECPublicKey>());
      expect(keyPair.privateKey, isA<ECPrivateKey>());
    });

    test('deriveSharedSecret returns same secret for both parties', () {
      final serviceA = E2EKeyExchangeService();
      final serviceB = E2EKeyExchangeService();

      final keyPairA = serviceA.generateKeyPair();
      final keyPairB = serviceB.generateKeyPair();

      final secretA =
          serviceA.deriveSharedSecret(keyPairA.privateKey, keyPairB.publicKey);
      final secretB =
          serviceB.deriveSharedSecret(keyPairB.privateKey, keyPairA.publicKey);

      expect(secretA, equals(secretB));
      expect(secretA.length, greaterThan(0));
    });
  });
}
