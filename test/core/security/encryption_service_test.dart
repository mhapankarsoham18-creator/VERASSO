import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/security/encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }
}

void main() {
  late EncryptionService encryptionService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    encryptionService = EncryptionService(storage: mockStorage);
  });

  group('EncryptionService Verification (Phase 3.1)', () {
    test('Initialization generates and stores master keys', () async {
      await encryptionService.initialize();
      
      final key = await mockStorage.read(key: 'encryption_master_key');
      final iv = await mockStorage.read(key: 'encryption_master_iv');
      final hiveKey = await mockStorage.read(key: 'hive_encryption_key');

      expect(key, isNotNull);
      expect(iv, isNotNull);
      expect(hiveKey, isNotNull);
    });

    test('Encrypt and decrypt roundtrip matches original text', () async {
      await encryptionService.initialize();
      const plainText = 'Verasso Secret Data';

      final encrypted = await encryptionService.encrypt(plainText);
      expect(encrypted, contains(':')); // Random IV format

      final decrypted = await encryptionService.decrypt(encrypted);
      expect(decrypted, plainText);
    });

    test('Password-based encryption roundtrip', () async {
      const password = 'StrongPassword123!';
      const plainText = 'Sensitive Project Data';

      final encrypted = await encryptionService.encryptWithPassword(plainText, password);
      expect(encrypted.split(':').length, 3); // salt:iv:cipher

      final decrypted = await encryptionService.decryptWithPassword(encrypted, password);
      expect(decrypted, plainText);
    });

    test('Decryption fails with wrong password', () async {
      const password = 'StrongPassword123!';
      const plainText = 'Sensitive Project Data';

      final encrypted = await encryptionService.encryptWithPassword(plainText, password);
      
      expect(
        () => encryptionService.decryptWithPassword(encrypted, 'WrongPassword'),
        throwsException,
      );
    });

    test('Hive key generation provides stable 32-byte key', () async {
      final key1 = await encryptionService.getHiveKey();
      final key2 = await encryptionService.getHiveKey();

      expect(key1.length, 32);
      expect(key1, key2); // Should be stable per session
    });
  });
}
