import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinenacl/ed25519.dart' as pinenacl;
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [MasterySignatureService] instance.
final masterySignatureServiceProvider =
    Provider((ref) => MasterySignatureService());

/// Service that handles generating and verifying cryptographically signed mastery transcripts.
class MasterySignatureService {
  static const _storageKey = 'mastery_signing_key_seed';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Cached key to avoid reading from storage on every call.
  pinenacl.SigningKey? _cachedKey;

  /// Generates a signed transcript for a user's skills.
  ///
  /// The transcript contains the [userId], a map of [skills] (name: mastery_level),
  /// and a timestamp, all signed with the provided [signingKey].
  String generateSignedTranscript({
    required String userId,
    required Map<String, double> skills,
    required pinenacl.SigningKey signingKey,
  }) {
    final payload = {
      'uid': userId,
      'skl': skills,
      'ts': DateTime.now().toIso8601String(),
    };

    final message = utf8.encode(jsonEncode(payload));
    final signature = signingKey.sign(Uint8List.fromList(message));

    final transcript = {
      'pay': payload,
      'sig': base64Encode(signature.signature),
      'pk': base64Encode(signingKey.verifyKey),
    };

    AppLogger.info('MasterySignature: Generated signed transcript for $userId');
    return jsonEncode(transcript);
  }

  /// Retrieves the global persistent signing key from secure storage.
  /// Generates and persists a new key on first use.
  Future<pinenacl.SigningKey?> getGlobalSigningKey() async {
    if (_cachedKey != null) return _cachedKey;

    try {
      final storedSeed = await _secureStorage.read(key: _storageKey);

      if (storedSeed != null) {
        final seedBytes = base64Decode(storedSeed);
        _cachedKey = pinenacl.SigningKey.fromSeed(seedBytes);
        return _cachedKey;
      }

      // First use: generate a new random seed and persist it
      final random = Random.secure();
      final seed = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        seed[i] = random.nextInt(256);
      }

      await _secureStorage.write(
        key: _storageKey,
        value: base64Encode(seed),
      );

      _cachedKey = pinenacl.SigningKey.fromSeed(seed);
      AppLogger.info('MasterySignature: Generated and stored new signing key');
      return _cachedKey;
    } catch (e) {
      AppLogger.error('MasterySignature: Failed to get signing key', error: e);
      return null;
    }
  }

  /// Verifies a signed mastery transcript.
  ///
  /// Returns `true` if the signature is valid for the contained payload and public key.
  bool verifyTranscript(String transcriptJson) {
    try {
      final transcript = jsonDecode(transcriptJson);
      final payload = transcript['pay'];
      final signature = base64Decode(transcript['sig']);
      final publicKey = base64Decode(transcript['pk']);

      final verifyKey = pinenacl.VerifyKey(publicKey);
      final message = utf8.encode(jsonEncode(payload));

      final isValid = verifyKey.verify(
        signature: pinenacl.Signature(signature),
        message: Uint8List.fromList(message),
      );

      if (isValid) {
        AppLogger.info(
            'MasterySignature: Successfully verified transcript for ${payload['uid']}');
      } else {
        AppLogger.warning(
            'MasterySignature: Verification FAILED for transcript');
      }

      return isValid;
    } catch (e) {
      AppLogger.error('MasterySignature: Verification error', error: e);
      return false;
    }
  }
}
