import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [ShieldService] instance.
final shieldServiceProvider = Provider((ref) => ShieldService());

/// Service for temporary, session-level encryption and data obfuscation.
///
/// Unlike [EncryptionService], which handles persistent data, [ShieldService]
/// provides ephemeral protection for in-memory payloads and UI-level
/// text scrambling to prevent shoulder surfing.
class ShieldService {
  encrypt.Key _sessionKey;
  encrypt.IV _sessionIv;
  DateTime _lastRotation;

  /// Creates a [ShieldService] and initializes ephemeral session keys.
  ShieldService()
      : _sessionKey = encrypt.Key.fromSecureRandom(32),
        _sessionIv = encrypt.IV.fromSecureRandom(16),
        _lastRotation = DateTime.now() {
    AppLogger.info('ShieldService: Session keys initialized');
  }

  /// The timestamp when the session keys were last rotated.
  DateTime get lastRotation => _lastRotation;

  /// Decrypts a base64 encoded payload using the current session key.
  String decryptPayload(String encryptedBase64) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_sessionKey));
      return encrypter.decrypt64(encryptedBase64, iv: _sessionIv);
    } catch (e) {
      return "[Decryption Failed - Session Key Changed?]";
    }
  }

  /// Encrypts a plain text payload into a base64 string using the current session key.
  String encryptPayload(String plainText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_sessionKey));
      return encrypter.encrypt(plainText, iv: _sessionIv).base64;
    } catch (e) {
      AppLogger.error('Encryption failed', error: e);
      return plainText;
    }
  }

  /// Regenerates the ephemeral session keys, rendering previous payloads unreadable.
  void rotateSessionKeys() {
    _sessionKey = encrypt.Key.fromSecureRandom(32);
    _sessionIv = encrypt.IV.fromSecureRandom(16);
    _lastRotation = DateTime.now();
    AppLogger.warning(
        'ShieldService: Session keys rotated! Previous data encrypted with old keys will be unreadable.');
  }

  /// Scrambles text visually into random alphanumeric and special characters
  /// while maintaining the original string length.
  String scrambleText(String input) {
    if (input.isEmpty) return "";
    final random = Random();
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+';

    return List.generate(input.length, (index) {
      // Don't scramble spaces to maintain sentence structure/flow
      if (input[index] == ' ') return ' ';
      return chars[random.nextInt(chars.length)];
    }).join();
  }
}
