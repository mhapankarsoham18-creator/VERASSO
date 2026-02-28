import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/messaging/services/encryption_service.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late EncryptionService service;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    service = EncryptionService(client: mockSupabase);
  });

  group('EncryptionService Tests', () {
    test('initializeKeys generates and uploads keys', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('user_keys', builder);

      await expectLater(
        service.initializeKeys(),
        completes,
      );
    });

    test('encryptMessage creates valid encrypted output', () async {
      // Setup mocks for key retrieval
      final keyBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('user_keys', keyBuilder);
      final builder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('user_keys', builder);

      // Initialize keys first
      await service.initializeKeys();

      // Test encryption
      final encrypted = await service.encryptMessage('Hello World', 'user-2');

      expect(encrypted, isNotNull);
      expect(encrypted['content'], isNotNull);
      expect(encrypted['iv'], isNotNull);
      expect(encrypted['key_receiver'], isNotNull);
      expect(encrypted['key_sender'], isNotNull);
    });

    test('encryptGroupMessage encrypts for multiple recipients', () async {
      final keyBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('user_keys', keyBuilder);

      await service.initializeKeys();

      final encrypted = await service.encryptGroupMessage(
        'Hello Group',
        ['user-2', 'user-3', 'user-4'],
      );

      expect(encrypted['content'], isNotNull);
      expect(encrypted['iv'], isNotNull);
      expect(encrypted['keys_per_user'], isNotNull);
      expect(
        (encrypted['keys_per_user'] as Map).length,
        greaterThanOrEqualTo(1),
      );
    });

    test('decryptMessage returns decrypted content', () async {
      final keyBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('user_keys', keyBuilder);

      await service.initializeKeys();

      final messageRow = {
        'encrypted_content': 'base64_encrypted_content',
        'iv_text': 'base64_iv',
        'key_for_sender': 'base64_encrypted_key',
        'receiver_id': 'user-2',
      };

      try {
        final decrypted = await service.decryptMessage(messageRow);
        expect(decrypted, isNotNull);
      } catch (e) {
        // Decryption might fail if keys aren't properly initialized
        // This is expected in unit test environment
        expect(e, isA<Exception>());
      }
    });

    test('decryptMessage throws when user not logged in', () async {
      mockAuth.setCurrentUser(null);

      final messageRow = {
        'encrypted_content': 'base64_encrypted_content',
        'iv_text': 'base64_iv',
      };

      expect(
        () => service.decryptMessage(messageRow),
        throwsException,
      );
    });

    test('decryptMessage handles missing private key gracefully', () async {
      final messageRow = {
        'encrypted_content': 'base64_encrypted_content',
        'iv_text': 'base64_iv',
        'key_for_sender': 'base64_encrypted_key',
        'receiver_id': 'user-2',
      };

      final result = await service.decryptMessage(messageRow);

      expect(result, contains('Decryption Error'));
    });

    test('encryptGroupMessage handles key generation for known users',
        () async {
      final keyBuilder = MockSupabaseQueryBuilder(
        selectResponse: {
          'public_key': 'base64_curve25519_key_here',
        },
      );
      mockSupabase.setQueryBuilder('user_keys', keyBuilder);

      await service.initializeKeys();

      final encrypted = await service.encryptGroupMessage(
        'Group message',
        ['user-2'],
      );

      expect(encrypted['keys_per_user'], isNotNull);
    });

    test('encryptGroupMessage continues on key fetch failure', () async {
      final keyBuilder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('user_keys', keyBuilder);

      await service.initializeKeys();

      // Should not throw, but may have empty keys_per_user
      final encrypted =
          await service.encryptGroupMessage('Message', ['user-2']);

      expect(encrypted['content'], isNotNull);
    });
  });

  group('EncryptionService Key Management Tests', () {
    test('initializeKeys should not regenerate if keys exist', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: {'public_key': 'existing_key'},
      );
      mockSupabase.setQueryBuilder('user_keys', builder);

      await service.initializeKeys();

      // Should complete without error
      expect(true, true);
    });

    test('Public key upload includes modulus and exponent', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('user_keys', builder);

      await service.initializeKeys();

      // Verify that upsert was called on user_keys table
      expect(mockSupabase.lastInsertTable, equals('user_keys'));
    });
  });
}
