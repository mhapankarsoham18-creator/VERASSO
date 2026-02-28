import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

// Helper for hex decoding since pinenacl doesn't always export it cleanly for external use in all versions
/// Helper utility for hex string encoding and decoding.
class Hex {
  /// Decodes a [hex] string into a list of byte integers.
  static List<int> decode(String hex) {
    var result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      var res = hex.substring(i, i + 2);
      result.add(int.parse(res, radix: 16));
    }
    return result;
  }
}

/// Service providing privacy-preserving cryptographic operations.
///
/// Implementation includes blinded identifiers for mesh networking
/// and Zero-Knowledge commitments for skill attestations.
class ZeroKnowledgeService {
  /// Creates a blinded identifier for mesh-based interaction.
  /// This prevents peers from linking a mesh node ID to a real global user ID.
  static String createBlindedId(String realId, String sessionSecret) {
    final bytes = utf8.encode('$realId:$sessionSecret');
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// Generates a "Proof of Skill" commitment.
  /// This creates a hash of the (skill_id + user_secret + salt).
  /// The user can share the commitment and the skill_id, and later "open" it
  /// by revealing the salt and secret if challenged, or use a signature to prove ownership.
  static String generateSkillCommitment(String skillId, String userSecret) {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('$skillId:$userSecret:$salt');
    final digest = sha256.convert(bytes);

    // Return Format: commitment:salt
    return '${digest.toString()}:$salt';
  }

  /// Verifies a skill commitment without knowing the userSecret initially (if provided later)
  /// Or verifies a signed attestation using Ed25519.
  static bool verifyAttestation({
    required String challenge,
    required String signatureHex,
    required String publicKeyHex,
  }) {
    try {
      final verifyKey = VerifyKey(Uint8List.fromList(Hex.decode(publicKeyHex)));
      final signature = Signature(Uint8List.fromList(Hex.decode(signatureHex)));
      final message = utf8.encode(challenge);

      return verifyKey.verify(message: message, signature: signature);
    } catch (e, stack) {
      AppLogger.error('ZK-Service: Verification failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return false;
    }
  }
}
