import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:verasso/features/messaging/services/mesh_network_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_envelope_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('MeshNetworkService Envelope Verification', () {
    const testSenderId = 'user_alice_123';
    const testNonce = 'unique-nonce-abc-456';
    const testTargetUserId = 'user_bob_789';

    /// Helper: sign an envelope using the sender's public key as the HMAC secret
    /// (mirrors the signing logic in verifyEnvelope for consistency).
    Future<String> createValidSignature(String publicKeyB64) async {
      final dataToSign = '$testSenderId:$testNonce:$testTargetUserId';
      final hmac = Hmac.sha256();
      final secretKey = SecretKey(base64Decode(publicKeyB64));
      final mac = await hmac.calculateMac(
        utf8.encode(dataToSign),
        secretKey: secretKey,
      );
      return base64Encode(mac.bytes);
    }

    /// Generate a valid test key pair
    Future<String> generateTestPublicKey() async {
      final keyExchange = X25519();
      final keyPair = await keyExchange.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      return base64Encode(publicKey.bytes);
    }

    test('rejects packets with empty signature', () async {
      final pubKey = await generateTestPublicKey();

      final result = await MeshNetworkService.verifyEnvelope(
        senderId: testSenderId,
        nonce: testNonce,
        targetUserId: testTargetUserId,
        senderSig: '', // Empty signature
        senderPublicKeyB64: pubKey,
      );

      expect(result, isFalse);
    });

    test('rejects packets with empty public key', () async {
      final result = await MeshNetworkService.verifyEnvelope(
        senderId: testSenderId,
        nonce: testNonce,
        targetUserId: testTargetUserId,
        senderSig: 'some-signature',
        senderPublicKeyB64: '', // Empty public key
      );

      expect(result, isFalse);
    });

    test('rejects packets with tampered signature', () async {
      final pubKey = await generateTestPublicKey();
      // Create a valid signature then tamper with it
      final validSig = await createValidSignature(pubKey);
      final tamperedSig = '${validSig.substring(0, validSig.length - 4)}XXXX';

      final result = await MeshNetworkService.verifyEnvelope(
        senderId: testSenderId,
        nonce: testNonce,
        targetUserId: testTargetUserId,
        senderSig: tamperedSig,
        senderPublicKeyB64: pubKey,
      );

      expect(result, isFalse);
    });

    test('rejects packets with wrong public key (impersonation)', () async {
      final realPubKey = await generateTestPublicKey();
      final fakePubKey = await generateTestPublicKey(); // Different key
      // Sign with the real key
      final sig = await createValidSignature(realPubKey);

      // But claim to be using the fake key — HMAC won't match
      final result = await MeshNetworkService.verifyEnvelope(
        senderId: testSenderId,
        nonce: testNonce,
        targetUserId: testTargetUserId,
        senderSig: sig,
        senderPublicKeyB64: fakePubKey, // Wrong key
      );

      expect(result, isFalse);
    });

    test('accepts packets with valid signature and matching public key', () async {
      final pubKey = await generateTestPublicKey();
      final validSig = await createValidSignature(pubKey);

      final result = await MeshNetworkService.verifyEnvelope(
        senderId: testSenderId,
        nonce: testNonce,
        targetUserId: testTargetUserId,
        senderSig: validSig,
        senderPublicKeyB64: pubKey,
      );

      expect(result, isTrue);
    });

    test('rejects packets with signature from different nonce', () async {
      final pubKey = await generateTestPublicKey();
      // Sign with a different nonce
      final dataToSign = '$testSenderId:different-nonce:$testTargetUserId';
      final hmac = Hmac.sha256();
      final secretKey = SecretKey(base64Decode(pubKey));
      final mac = await hmac.calculateMac(
        utf8.encode(dataToSign),
        secretKey: secretKey,
      );
      final wrongNonceSig = base64Encode(mac.bytes);

      final result = await MeshNetworkService.verifyEnvelope(
        senderId: testSenderId,
        nonce: testNonce, // Original nonce
        targetUserId: testTargetUserId,
        senderSig: wrongNonceSig, // Signed with different nonce
        senderPublicKeyB64: pubKey,
      );

      expect(result, isFalse);
    });
  });
}
