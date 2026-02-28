import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Service for handling End-to-End Encryption key exchange using EC Diffie-Hellman.
///
/// This implementation currently uses the `secp256r1` (P-256) curve to allow
/// two users to derive a shared secret over an insecure communication channel,
/// providing the foundation for secure messaging and data sharing.
class E2EKeyExchangeService {
  final ECDomainParameters _domainParams;
  final SecureRandom _secureRandom;

  /// Creates an [E2EKeyExchangeService] and initializes elliptic curve parameters.
  E2EKeyExchangeService()
      : _domainParams = ECDomainParameters(
            'secp256r1'), // Using standard registry lookup if available, or fallback to explicit parameters
        _secureRandom = _getSecureRandom();

  /// Derive shared secret from own private key and other's public key
  /// Returns the shared secret as Uint8List
  Uint8List deriveSharedSecret(PrivateKey privateKey, PublicKey publicKey) {
    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey as ECPrivateKey);
    final secret = agreement.calculateAgreement(publicKey as ECPublicKey);
    return _bigIntToBytes(secret);
  }

  /// Generate a new key pair (Public & Private)
  AsymmetricKeyPair<PublicKey, PrivateKey> generateKeyPair() {
    final keyGen = ECKeyGenerator();
    keyGen.init(ParametersWithRandom(
        ECKeyGeneratorParameters(_domainParams), _secureRandom));
    return keyGen.generateKeyPair();
  }

  Uint8List _bigIntToBytes(BigInt number) {
    var hex = number.toRadixString(16);
    if (hex.length % 2 != 0) hex = '0$hex';
    var len = hex.length ~/ 2;
    var bytes = Uint8List(len);
    for (var i = 0; i < len; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  /// Uses OS-level entropy via [Random.secure] for cryptographic safety.
  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seed = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      seed[i] = random.nextInt(256);
    }
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }
}
