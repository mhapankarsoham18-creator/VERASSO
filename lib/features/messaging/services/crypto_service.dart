import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  final _keyExchange = X25519();
  final _cipher = AesGcm.with256bits();

  /// Generates a new X25519 key pair, returning the raw bytes encoded to Base64 strings.
  /// Map contains 'publicKey' and 'privateKey'.
  Future<Map<String, String>> generateKeyPair() async {
    final keyPair = await _keyExchange.newKeyPair();
    
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();

    return {
      'publicKey': base64Encode(publicKey.bytes),
      'privateKey': base64Encode(privateKey),
    };
  }

  /// Derives the shared secret and encrypts the plaintext.
  /// Returns a map with 'ciphertext', 'nonce', and 'mac' all base64 encoded.
  Future<Map<String, String>> encryptMessage({
    required String plaintext,
    required String myPrivateKeyB64,
    required String peerPublicKeyB64,
  }) async {
    // Reconstruct keys
    final keyPair = SimpleKeyPairData(
      base64Decode(myPrivateKeyB64),
      publicKey: SimplePublicKey(base64Decode(peerPublicKeyB64), type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final peerPublicKey = SimplePublicKey(
      base64Decode(peerPublicKeyB64),
      type: KeyPairType.x25519,
    );

    // ECDH Shared Secret derived
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: peerPublicKey,
    );

    // Encrypt using AES-256-GCM
    final secretBytes = await sharedSecret.extractBytes();
    final aesKey = SecretKey(secretBytes);
    final nonce = _cipher.newNonce();
    
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: aesKey,
      nonce: nonce,
    );

    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  /// Derives the shared secret and decrypts the ciphertext.
  /// Returns the original plaintext.
  Future<String> decryptMessage({
    required String ciphertextB64,
    required String nonceB64,
    required String macB64,
    required String myPrivateKeyB64,
    required String peerPublicKeyB64,
  }) async {
    // Reconstruct keys
    final keyPair = SimpleKeyPairData(
      base64Decode(myPrivateKeyB64),
      publicKey: SimplePublicKey(base64Decode(peerPublicKeyB64), type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final peerPublicKey = SimplePublicKey(
      base64Decode(peerPublicKeyB64),
      type: KeyPairType.x25519,
    );

    // ECDH Shared Secret
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: peerPublicKey,
    );

    final secretBytes = await sharedSecret.extractBytes();
    final aesKey = SecretKey(secretBytes);
    
    final secretBox = SecretBox(
      base64Decode(ciphertextB64),
      nonce: base64Decode(nonceB64),
      mac: Mac(base64Decode(macB64)),
    );

    // Decrypt
    final cleartextBytes = await _cipher.decrypt(
      secretBox,
      secretKey: aesKey,
    );

    return utf8.decode(cleartextBytes);
  }
}
