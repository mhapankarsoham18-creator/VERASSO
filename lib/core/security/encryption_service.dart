import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Service providing AES-256 encryption for protecting sensitive AR project data.
///
/// It supports cross-session persistence of master keys via secure storage,
/// provides utility methods for JSON encryption, and supports both legacy
/// and modern IV formats for backward compatibility.
class EncryptionService {
  /// The required length for an AES-256 key (32 bytes).
  /// The required length for a master encryption key (32 bytes).
  static const int keyLength = 32;

  /// The required length for an initialization vector (16 bytes).
  static const int ivLength = 16;

  // Storage keys for secure persistence
  static const String _masterKeyStorageKey = 'encryption_master_key';
  static const String _masterIvStorageKey = 'encryption_master_iv';
  static const String _hiveEncryptionKeyStorageKey = 'hive_encryption_key';

  final FlutterSecureStorage _secureStorage;

  /// Creates an [EncryptionService].
  /// Optionally accepts a custom [FlutterSecureStorage] instance for testing.
  EncryptionService({FlutterSecureStorage? storage})
      : _secureStorage = storage ?? const FlutterSecureStorage();

  /// Clear all encryption keys (logout/reset)
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _masterKeyStorageKey);
    await _secureStorage.delete(key: _masterIvStorageKey);
  }

  /// Decrypt data with support for legacy (fixed IV) and new (random IV) formats
  Future<String> decrypt(String encryptedText) async {
    try {
      final keyString = await _secureStorage.read(key: _masterKeyStorageKey);
      if (keyString == null) {
        throw Exception('Encryption keys not initialized');
      }

      final key = encrypt_lib.Key(base64Decode(keyString));
      final encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));

      // Check for new format (IV:Ciphertext)
      if (encryptedText.contains(':')) {
        final parts = encryptedText.split(':');
        if (parts.length == 2) {
          final iv = encrypt_lib.IV.fromBase64(parts[0]);
          return encrypter.decrypt64(parts[1], iv: iv);
        }
      }

      // Fallback to legacy format (Master IV)
      final ivString = await _secureStorage.read(key: _masterIvStorageKey);
      if (ivString != null) {
        final iv = encrypt_lib.IV(base64Decode(ivString));
        return encrypter.decrypt64(encryptedText, iv: iv);
      }

      throw Exception('Invalid encrypted format and no legacy IV found');
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Decrypt JSON data
  Future<Map<String, dynamic>> decryptJson(String encryptedData) async {
    final jsonString = await decrypt(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Decrypt with custom password
  Future<String> decryptWithPassword(
      String encryptedData, String password) async {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 3) {
        throw Exception('Invalid encrypted data format');
      }

      final salt = base64Decode(parts[0]);
      final iv = base64Decode(parts[1]);
      final encrypted = parts[2];

      // Derive same key from password and salt
      final key = await _deriveKeyFromPassword(password, salt);

      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(encrypt_lib.Key(key), mode: encrypt_lib.AESMode.cbc),
      );
      final decrypted = encrypter.decrypt64(encrypted, iv: encrypt_lib.IV(iv));

      return decrypted;
    } catch (e) {
      throw Exception('Password decryption failed: $e');
    }
  }

  /// Encrypt data using AES-256-CBC with random IV
  Future<String> encrypt(String plainText) async {
    try {
      final keyString = await _secureStorage.read(key: _masterKeyStorageKey);
      if (keyString == null) {
        throw Exception('Encryption keys not initialized');
      }

      final key = encrypt_lib.Key(base64Decode(keyString));

      // Generate random IV for this specific message
      final iv = encrypt_lib.IV.fromLength(ivLength);

      final encrypter = encrypt_lib.Encrypter(
          encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Return format: base64(IV):base64(Ciphertext)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Encrypt JSON data
  Future<String> encryptJson(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString);
  }

  /// Encrypt with custom password (for password-protected projects)
  Future<String> encryptWithPassword(String plainText, String password) async {
    try {
      // Derive key from password using PBKDF2
      final salt = _generateSecureKey(16);
      final key = await _deriveKeyFromPassword(password, salt);
      final iv = _generateSecureKey(ivLength);

      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(encrypt_lib.Key(key), mode: encrypt_lib.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt(plainText, iv: encrypt_lib.IV(iv));

      // Store salt:iv:encrypted
      final combined =
          '${base64Encode(salt)}:${base64Encode(iv)}:${encrypted.base64}';
      return combined;
    } catch (e) {
      throw Exception('Password encryption failed: $e');
    }
  }

  /// Get encryption key for Hive boxes (32 bytes)
  Future<Uint8List> getHiveKey() async {
    String? keyStr =
        await _secureStorage.read(key: _hiveEncryptionKeyStorageKey);

    if (keyStr == null) {
      // Lazy initialization if not present
      final key = _generateSecureKey(keyLength);
      keyStr = base64Encode(key);
      await _secureStorage.write(
          key: _hiveEncryptionKeyStorageKey, value: keyStr);
    }

    return base64Decode(keyStr);
  }

  /// Initialize encryption service and generate master key if needed
  Future<void> initialize() async {
    final existingKey = await _secureStorage.read(key: _masterKeyStorageKey);

    if (existingKey == null) {
      // Generate new master key
      final key = _generateSecureKey(keyLength);
      final iv = _generateSecureKey(ivLength);
      final hiveKey = _generateSecureKey(keyLength);

      await _secureStorage.write(
        key: _masterKeyStorageKey,
        value: base64Encode(key),
      );
      await _secureStorage.write(
        key: _masterIvStorageKey,
        value: base64Encode(iv),
      );
      await _secureStorage.write(
        key: _hiveEncryptionKeyStorageKey,
        value: base64Encode(hiveKey),
      );
    }
  }

  /// Check if encryption is initialized
  Future<bool> isInitialized() async {
    final key = await _secureStorage.read(key: _masterKeyStorageKey);
    return key != null;
  }

  /// Derive encryption key from password using PBKDF2
  Future<Uint8List> _deriveKeyFromPassword(
      String password, Uint8List salt) async {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));

    pbkdf2.init(Pbkdf2Parameters(salt, 100000,
        keyLength)); // 100,000 iterations for stronger key derivation

    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    return pbkdf2.process(passwordBytes);
  }

  /// Generate cryptographically secure random key
  Uint8List _generateSecureKey(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

/// Service for performing field-level encryption on structured data maps.
///
/// This allows for granular protection of specific sensitive fields within a
/// larger data structure, while leaving non-sensitive data in plain text.
class FieldEncryptionService {
  final EncryptionService _encryptionService;

  /// Creates a [FieldEncryptionService] using the provided [encryptionService].
  FieldEncryptionService(this._encryptionService);

  /// Decrypt specific fields in a map
  Future<Map<String, dynamic>> decryptFields(
    Map<String, dynamic> data,
    List<String> fieldsToDecrypt,
  ) async {
    final result = Map<String, dynamic>.from(data);

    for (final fieldName in fieldsToDecrypt) {
      if (result.containsKey(fieldName) &&
          result['${fieldName}_encrypted'] == true) {
        final encrypted = result[fieldName] as String;
        final decrypted = await _encryptionService.decrypt(encrypted);
        result[fieldName] = decrypted;
        result.remove('${fieldName}_encrypted');
      }
    }

    return result;
  }

  /// Encrypt specific fields in a map
  Future<Map<String, dynamic>> encryptFields(
    Map<String, dynamic> data,
    List<String> fieldsToEncrypt,
  ) async {
    final result = Map<String, dynamic>.from(data);

    for (final fieldName in fieldsToEncrypt) {
      if (result.containsKey(fieldName)) {
        final value = result[fieldName];
        if (value != null) {
          final encrypted = await _encryptionService.encrypt(value.toString());
          result[fieldName] = encrypted;
          result['${fieldName}_encrypted'] = true;
        }
      }
    }

    return result;
  }
}
