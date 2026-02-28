import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinenacl/tweetnacl.dart';
import 'package:pinenacl/x25519.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import '../../../../core/monitoring/app_logger.dart';
import '../../../../core/services/supabase_service.dart';

/// Provider for the [EncryptionService] instance.
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Service responsible for End-to-End Encryption (E2EE) using Curve25519 (PineNaCl).
class EncryptionService {
  static const _privateKeyKey = 'user_e2e_private_key';
  static const _publicKeyKey = 'user_e2e_public_key';
  final FlutterSecureStorage _storage;
  final SupabaseClient _client;

  /// Creates an [EncryptionService] instance.
  EncryptionService({
    SupabaseClient? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? SupabaseService.client,
        _storage = storage ?? const FlutterSecureStorage();

  // --- Key Management ---

  /// Decrypts a message row using PineNaCl.
  Future<String> decryptMessage(Map<String, dynamic> messageRow,
      {bool isGroup = false}) async {
    try {
      final myId = _client.auth.currentUser?.id;
      if (myId == null) {
        throw Exception('Not logged in');
      }

      // 1. Get my Private Key
      final myPrivKeyBase64 = await _storage.read(key: _privateKeyKey);
      if (myPrivKeyBase64 == null) throw Exception('Local private key missing');
      final myPrivKey = PrivateKey(base64Decode(myPrivKeyBase64));

      final senderId = messageRow['sender_id'];
      final String scheme = messageRow['scheme'] ?? 'pinenacl_v1';

      if (scheme == 'hybrid_pinenacl_v1' && isGroup) {
        // --- Hybrid Decryption for Group Chat ---
        final encryptedKeys =
            messageRow['encrypted_keys'] as Map<String, dynamic>?;
        if (encryptedKeys == null || !encryptedKeys.containsKey(myId)) {
          throw Exception('Session key not found for current user');
        }

        // a. Get Sender's Public Key
        final senderPubKeyBase64 = await _getPublicKey(senderId);
        if (senderPubKeyBase64 == null) {
          throw Exception('Sender public key missing');
        }
        final senderPubKey = PublicKey(base64Decode(senderPubKeyBase64));

        // b. Decrypt Session Key using NaCl Box
        final box = Box(myPrivateKey: myPrivKey, theirPublicKey: senderPubKey);
        final encryptedSessionKey = base64Decode(encryptedKeys[myId]);
        final sessionKey = box.decrypt(ByteList(encryptedSessionKey));

        // c. Decrypt Content using NaCl SecretBox
        final secretBox = SecretBox(sessionKey);
        final cipherText = base64Decode(messageRow['encrypted_content']);
        final nonce = base64Decode(messageRow['iv_text']);

        final decryptedBytes = secretBox.decrypt(
          ByteList(cipherText),
          nonce: nonce,
        );
        return utf8.decode(decryptedBytes);
      }

      // --- Legacy / Direct Decryption ---
      final String peerId = (isGroup)
          ? senderId
          : (messageRow['sender_id'] == myId
              ? messageRow['receiver_id']
              : messageRow['sender_id']);

      final peerPubKeyBase64 = await _getPublicKey(peerId);
      if (peerPubKeyBase64 == null) {
        throw Exception('Peer public key not found');
      }
      final peerPubKey = PublicKey(base64Decode(peerPubKeyBase64));

      final box = Box(myPrivateKey: myPrivKey, theirPublicKey: peerPubKey);
      final cipherText = base64Decode(messageRow['encrypted_content']);
      final nonce = base64Decode(messageRow['iv_text']);

      final decryptedBytes = box.decrypt(
        ByteList(cipherText),
        nonce: Uint8List.fromList(nonce),
      );

      return utf8.decode(decryptedBytes);
    } catch (e, stack) {
      AppLogger.error('Decryption failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return '[Decryption Error]';
    }
  }

  /// Encrypts content for multiple receivers (Group Chat).
  /// Returns [encryptedContent, iv, encryptedKeysPerUser]
  Future<Map<String, dynamic>> encryptGroupMessage(
      String content, List<String> receiverIds) async {
    try {
      // 1. Generate a random 32-byte session key
      final sessionKey = TweetNaCl.randombytes(32);
      final secretBox = SecretBox(sessionKey);

      // 2. Encrypt content once with this session key
      final encryptedBytes = secretBox.encrypt(utf8.encode(content));

      // 3. Encrypt the session key for each recipient using their public key (NaCl Box)
      final myPrivKeyBase64 = await _storage.read(key: _privateKeyKey);
      if (myPrivKeyBase64 == null) {
        throw Exception('Local private key missing');
      }
      final myPrivKey = PrivateKey(base64Decode(myPrivKeyBase64));

      final Map<String, String> encryptedKeys = {};
      for (final receiverId in receiverIds) {
        final theirPubKeyBase64 = await _getPublicKey(receiverId);
        if (theirPubKeyBase64 != null) {
          final box = Box(
              myPrivateKey: myPrivKey,
              theirPublicKey: PublicKey(base64Decode(theirPubKeyBase64)));
          final encryptedSessionKey = box.encrypt(sessionKey);
          // Combine nonce + cipher for transmission
          encryptedKeys[receiverId] = base64Encode(encryptedSessionKey);
        }
      }

      return {
        'content': base64Encode(encryptedBytes.cipherText),
        'iv': base64Encode(encryptedBytes.nonce),
        'encrypted_keys': encryptedKeys,
        'scheme': 'hybrid_pinenacl_v1',
      };
    } catch (e, stack) {
      AppLogger.error('Group encryption failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  // --- Encryption / Decryption ---

  /// Encrypts content for a single receiver (Direct Chat).
  /// Uses XSalsa20-Poly1305 (NaCl Box).
  Future<Map<String, String>> encryptMessage(
    String content,
    String receiverId,
  ) async {
    try {
      // 1. Get my Private Key
      final myPrivKeyBase64 = await _storage.read(key: _privateKeyKey);
      if (myPrivKeyBase64 == null) throw Exception('Local private key missing');
      final myPrivKey = PrivateKey(base64Decode(myPrivKeyBase64));

      // 2. Get receiver's Public Key from Supabase
      final theirPubKeyBase64 = await _getPublicKey(receiverId);
      if (theirPubKeyBase64 == null) {
        throw Exception('Recipient public key not found');
      }
      final theirPubKey = PublicKey(base64Decode(theirPubKeyBase64));

      // 3. Create a Box and encrypt
      final box = Box(myPrivateKey: myPrivKey, theirPublicKey: theirPubKey);
      final encryptedBytes = box.encrypt(utf8.encode(content));

      // PineNaCl Box.encrypt returns a list where the first 24 bytes are the nonce
      // if using standard Box. But we can also handle it explicitly.
      // Box.encrypt(plaintext) returns EncryptedMessage which contains nonce + cipher

      return {
        'content': base64Encode(encryptedBytes.cipherText),
        'iv': base64Encode(encryptedBytes.nonce),
        'key_receiver': 'pinenacl_v1', // Metadata identifying the scheme
        'key_sender': 'pinenacl_v1',
      };
    } catch (e, stack) {
      AppLogger.error('Encryption failed for $receiverId', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Initializes encryption keys. Generates and uploads new keys if they don't exist.
  Future<void> initializeKeys() async {
    final hasKey = await _storage.containsKey(key: _privateKeyKey);
    if (!hasKey) {
      await _generateAndUploadKeys();
    }
  }

  Future<void> _generateAndUploadKeys() async {
    try {
      // 1. Generate Curve25519 Key Pair
      final privateKey = PrivateKey.generate();
      final publicKey = privateKey.publicKey;

      // 2. Save locally in secure storage
      await _storage.write(
        key: _privateKeyKey,
        value: base64Encode(privateKey),
      );
      await _storage.write(
        key: _publicKeyKey,
        value: base64Encode(publicKey),
      );

      // 3. Upload Public Key to Supabase user_keys table
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _client.from('user_keys').upsert({
          'user_id': userId,
          'public_key': base64Encode(publicKey),
        });
      }
      AppLogger.info('E2EE Keys generated and uploaded for $userId');
    } catch (e, stack) {
      AppLogger.error('Failed to generate E2EE keys', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  // --- Helpers ---

  Future<String?> _getPublicKey(String userId) async {
    try {
      final response = await _client
          .from('user_keys')
          .select('public_key')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      return response['public_key'] as String;
    } catch (e, stack) {
      AppLogger.error('Failed to fetch public key for $userId', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }
}
