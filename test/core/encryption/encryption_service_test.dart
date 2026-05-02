import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';

/// Tests for the E2E encryption logic used by CryptoService.
/// We test the raw cryptography primitives here without depending on
/// flutter_secure_storage (which requires a platform).
void main() {
  group('X25519 Key Exchange', () {
    final keyExchange = X25519();

    test('generates a valid key pair', () async {
      final keyPair = await keyExchange.newKeyPair();

      final publicKey = await keyPair.extractPublicKey();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

      expect(publicKey.bytes.length, 32); // X25519 keys are 32 bytes
      expect(privateKeyBytes.length, 32);
    });

    test('two parties derive the same shared secret', () async {
      // Alice generates a key pair
      final aliceKeyPair = await keyExchange.newKeyPair();
      final alicePublicKey = await aliceKeyPair.extractPublicKey();

      // Bob generates a key pair
      final bobKeyPair = await keyExchange.newKeyPair();
      final bobPublicKey = await bobKeyPair.extractPublicKey();

      // Alice derives shared secret using her private key and Bob's public key
      final aliceSharedSecret = await keyExchange.sharedSecretKey(
        keyPair: aliceKeyPair,
        remotePublicKey: bobPublicKey,
      );

      // Bob derives shared secret using his private key and Alice's public key
      final bobSharedSecret = await keyExchange.sharedSecretKey(
        keyPair: bobKeyPair,
        remotePublicKey: alicePublicKey,
      );

      final aliceBytes = await aliceSharedSecret.extractBytes();
      final bobBytes = await bobSharedSecret.extractBytes();

      expect(aliceBytes, equals(bobBytes));
    });
  });

  group('AES-256-GCM Encrypt/Decrypt', () {
    final cipher = AesGcm.with256bits();
    final keyExchange = X25519();

    test('encrypt then decrypt returns original plaintext', () async {
      const originalMessage = 'Hello from Verasso E2E!';

      // Generate two key pairs (simulating two users)
      final senderKeyPair = await keyExchange.newKeyPair();
      final receiverKeyPair = await keyExchange.newKeyPair();
      final receiverPublicKey = await receiverKeyPair.extractPublicKey();
      final senderPublicKey = await senderKeyPair.extractPublicKey();

      // Sender encrypts
      final sharedSecret = await keyExchange.sharedSecretKey(
        keyPair: senderKeyPair,
        remotePublicKey: receiverPublicKey,
      );
      final secretBytes = await sharedSecret.extractBytes();
      final aesKey = SecretKey(secretBytes);

      final secretBox = await cipher.encrypt(
        utf8.encode(originalMessage),
        secretKey: aesKey,
      );

      // Simulate transmission: base64 encode everything
      final ciphertextB64 = base64Encode(secretBox.cipherText);
      final nonceB64 = base64Encode(secretBox.nonce);
      final macB64 = base64Encode(secretBox.mac.bytes);

      // Receiver decrypts
      final receiverSharedSecret = await keyExchange.sharedSecretKey(
        keyPair: receiverKeyPair,
        remotePublicKey: senderPublicKey,
      );
      final receiverSecretBytes = await receiverSharedSecret.extractBytes();
      final receiverAesKey = SecretKey(receiverSecretBytes);

      final reconstructedBox = SecretBox(
        base64Decode(ciphertextB64),
        nonce: base64Decode(nonceB64),
        mac: Mac(base64Decode(macB64)),
      );

      final decrypted = await cipher.decrypt(
        reconstructedBox,
        secretKey: receiverAesKey,
      );

      expect(utf8.decode(decrypted), equals(originalMessage));
    });

    test('decrypt with wrong key fails', () async {
      const originalMessage = 'Secret data';

      final senderKeyPair = await keyExchange.newKeyPair();
      final receiverKeyPair = await keyExchange.newKeyPair();
      final receiverPublicKey = await receiverKeyPair.extractPublicKey();

      final sharedSecret = await keyExchange.sharedSecretKey(
        keyPair: senderKeyPair,
        remotePublicKey: receiverPublicKey,
      );
      final secretBytes = await sharedSecret.extractBytes();
      final aesKey = SecretKey(secretBytes);

      final secretBox = await cipher.encrypt(
        utf8.encode(originalMessage),
        secretKey: aesKey,
      );

      // Try to decrypt with a completely different key
      final wrongKeyPair = await keyExchange.newKeyPair();
      final wrongShared = await keyExchange.sharedSecretKey(
        keyPair: wrongKeyPair,
        remotePublicKey: receiverPublicKey,
      );
      final wrongBytes = await wrongShared.extractBytes();
      final wrongAesKey = SecretKey(wrongBytes);

      expect(
        () async => await cipher.decrypt(secretBox, secretKey: wrongAesKey),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('encrypted output is not the same as plaintext', () async {
      const message = 'This should be unreadable after encryption';

      final keyPair = await keyExchange.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();

      final sharedSecret = await keyExchange.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: publicKey,
      );
      final secretBytes = await sharedSecret.extractBytes();
      final aesKey = SecretKey(secretBytes);

      final secretBox = await cipher.encrypt(
        utf8.encode(message),
        secretKey: aesKey,
      );

      final ciphertext = base64Encode(secretBox.cipherText);
      expect(ciphertext, isNot(equals(message)));
    });
  });
}
