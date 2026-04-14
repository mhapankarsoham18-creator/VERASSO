import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/messaging/services/crypto_service.dart';

void main() {
  group('CryptoService E2E Tests', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService();
    });

    test('generateKeyPair creates valid base64 keys', () async {
      final keys = await cryptoService.generateKeyPair();
      expect(keys.containsKey('publicKey'), true);
      expect(keys.containsKey('privateKey'), true);
      expect(keys['publicKey']!.isNotEmpty, true);
      expect(keys['privateKey']!.isNotEmpty, true);
    });

    test('encrypt and decrypt a message successfully between two peers', () async {
      // Alice and Bob generate their respective keys
      final aliceKeys = await cryptoService.generateKeyPair();
      final bobKeys = await cryptoService.generateKeyPair();

      const plaintext = "Hello Bob, this is a secure message from Alice! 🚀 123";

      // Alice encrypts for Bob using Alice's private key and Bob's public key
      final encryptedPayload = await cryptoService.encryptMessage(
        plaintext: plaintext,
        myPrivateKeyB64: aliceKeys['privateKey']!,
        peerPublicKeyB64: bobKeys['publicKey']!,
      );

      expect(encryptedPayload.containsKey('ciphertext'), true);
      expect(encryptedPayload.containsKey('nonce'), true);
      expect(encryptedPayload.containsKey('mac'), true);

      // Bob decrypts the message using Bob's private key and Alice's public key
      final decryptedData = await cryptoService.decryptMessage(
        ciphertextB64: encryptedPayload['ciphertext']!,
        nonceB64: encryptedPayload['nonce']!,
        macB64: encryptedPayload['mac']!,
        myPrivateKeyB64: bobKeys['privateKey']!,
        peerPublicKeyB64: aliceKeys['publicKey']!,
      );

      // Plaintext should perfectly match
      expect(decryptedData, plaintext);
    });

    test('decrypting with the wrong keys throws an error', () async {
      final aliceKeys = await cryptoService.generateKeyPair();
      final bobKeys = await cryptoService.generateKeyPair();
      final eveKeys = await cryptoService.generateKeyPair();

      const plaintext = "Top secret base details";

      final encryptedPayload = await cryptoService.encryptMessage(
        plaintext: plaintext,
        myPrivateKeyB64: aliceKeys['privateKey']!,
        peerPublicKeyB64: bobKeys['publicKey']!,
      );

      // Eve attempts to decrypt message meant for Bob using her own private key
      expect(
        () async {
          await cryptoService.decryptMessage(
            ciphertextB64: encryptedPayload['ciphertext']!,
            nonceB64: encryptedPayload['nonce']!,
            macB64: encryptedPayload['mac']!,
            myPrivateKeyB64: eveKeys['privateKey']!,
            peerPublicKeyB64: aliceKeys['publicKey']!,
          );
        },
        throwsA(isA<Exception>()), 
      );
      
      // Bob attempts to decrypt but thinks it came from Eve (wrong sender public key)
      expect(
        () async {
          await cryptoService.decryptMessage(
            ciphertextB64: encryptedPayload['ciphertext']!,
            nonceB64: encryptedPayload['nonce']!,
            macB64: encryptedPayload['mac']!,
            myPrivateKeyB64: bobKeys['privateKey']!,
            peerPublicKeyB64: eveKeys['publicKey']!,
          );
        },
        throwsA(isA<Exception>()), 
      );
    });
    
    test('decrypting with altered ciphertext fails MAC validation', () async {
       final aliceKeys = await cryptoService.generateKeyPair();
       final bobKeys = await cryptoService.generateKeyPair();
       const plaintext = "Financial records";
       
       final encryptedPayload = await cryptoService.encryptMessage(
          plaintext: plaintext,
          myPrivateKeyB64: aliceKeys['privateKey']!,
          peerPublicKeyB64: bobKeys['publicKey']!,
       );
       
       // Tamper with the ciphertext slightly
       final base64String = encryptedPayload['ciphertext']!;
       // Change the last character to tamper it
       final tamperedCiphertext = base64String.substring(0, base64String.length - 1) + (base64String[base64String.length - 1] == 'A' ? 'B' : 'A');
       
       expect(
        () async {
          await cryptoService.decryptMessage(
            ciphertextB64: tamperedCiphertext,
            nonceB64: encryptedPayload['nonce']!,
            macB64: encryptedPayload['mac']!,
            myPrivateKeyB64: bobKeys['privateKey']!,
            peerPublicKeyB64: aliceKeys['publicKey']!,
          );
        },
        throwsA(isA<Exception>()), 
      );
    });
  });
}
