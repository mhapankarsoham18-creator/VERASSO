import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/messaging/services/messaging_encryption_service.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockEncryptionService mockEncryptionService;
  late MessagingEncryptionService service;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    mockEncryptionService = MockEncryptionService();
    service = MessagingEncryptionService(
      client: mockSupabase,
      encryptionService: mockEncryptionService,
    );
  });

  group('MessagingEncryptionService Tests', () {
    test('encryptMessage encrypts plaintext for recipient', () async {
      // Setup mock for conversation key creation
      final builder = MockSupabaseQueryBuilder(
        selectResponse: null, // No existing key
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      mockEncryptionService.setEncryptResult('encrypted:content');

      final encrypted = await service.encryptMessage('Hello', 'user-2');

      expect(encrypted, 'encrypted:content');
    });

    test('encryptMessage throws on encryption failure', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: null,
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      mockEncryptionService.setEncryptThrow(
        Exception('Encryption failed'),
      );

      expect(
        () => service.encryptMessage('Hello', 'user-2'),
        throwsException,
      );
    });

    test('decryptMessage decrypts encrypted content from sender', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: null,
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      mockEncryptionService.setDecryptResult('Hello World');

      final decrypted = await service.decryptMessage(
        'encrypted:content',
        'user-2',
      );

      expect(decrypted, 'Hello World');
    });

    test('decryptMessage throws on decryption failure', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: null,
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      mockEncryptionService.setDecryptThrow(
        Exception('Decryption failed'),
      );

      expect(
        () => service.decryptMessage('encrypted:content', 'user-2'),
        throwsException,
      );
    });

    test('encryptMessage reuses existing conversation key', () async {
      final existingKey = 'existing-key-base64';
      final builder = MockSupabaseQueryBuilder(
        selectResponse: {'encryption_key': existingKey},
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      mockEncryptionService.setEncryptResult('encrypted:content');

      await service.encryptMessage('Hello', 'user-2');

      // Verify we didn't insert a new key
      expect(mockSupabase.lastInsertTable, isNull);
    });

    test('encryptMessage creates new key if none exists', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: null,
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      mockEncryptionService.setEncryptResult('encrypted:content');

      await service.encryptMessage('Hello', 'user-2');

      // Should have attempted to insert a key
      expect(mockSupabase.lastInsertTable, 'conversation_keys');
    });

    test('rotateConversationKey rotates key for conversation', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      await expectLater(
        service.rotateConversationKey('user-2'),
        completes,
      );

      expect(mockSupabase.lastUpdateTable, 'conversation_keys');
    });

    test('rotateConversationKey throws when user not authenticated', () async {
      mockAuth.setCurrentUser(null);

      expect(
        () => service.rotateConversationKey('user-2'),
        throwsException,
      );
    });

    test('searchMessages searches all conversations for query', () async {
      // Mock conversations list
      final convBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {'id': 'conv-1', 'user_1_id': 'user-1', 'user_2_id': 'user-2'},
      ]);
      mockSupabase.setQueryBuilder('conversations', convBuilder);

      // Mock messages list
      final msgBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {'id': 'msg-1', 'content': 'encrypted:hello'},
        {'id': 'msg-2', 'content': 'encrypted:world'},
      ]);
      mockSupabase.setQueryBuilder('messages', msgBuilder);

      mockEncryptionService
        ..setDecryptResult('hello world')
        ..setDecryptResult('goodbye world');

      final matchingIds = await service.searchMessages('world');

      expect(matchingIds, containsAll(['msg-1', 'msg-2']));
    });

    test('searchMessages returns empty list when no matches found', () async {
      final convBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {'id': 'conv-1', 'user_1_id': 'user-1', 'user_2_id': 'user-2'},
      ]);
      mockSupabase.setQueryBuilder('conversations', convBuilder);

      final msgBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {'id': 'msg-1', 'content': 'encrypted:hello'},
      ]);
      mockSupabase.setQueryBuilder('messages', msgBuilder);

      mockEncryptionService.setDecryptResult('hello there');

      final matchingIds = await service.searchMessages('notfound');

      expect(matchingIds, isEmpty);
    });

    test('searchMessages returns empty list when user not authenticated',
        () async {
      mockAuth.setCurrentUser(null);

      final results = await service.searchMessages('test');

      expect(results, isEmpty);
    });

    test('verifyMessageIntegrity returns true for valid HMAC', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: {'encryption_key': 'test-key'},
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      final message = 'encrypted:content';
      final expectedHmac = service.calculateHmacPublic(message, 'test-key');

      final isValid = await service.verifyMessageIntegrity(
        message,
        'user-2',
        expectedHmac,
      );

      expect(isValid, true);
    });

    test('verifyMessageIntegrity returns false for invalid HMAC', () async {
      final builder = MockSupabaseQueryBuilder(
        selectResponse: {'encryption_key': 'test-key'},
      );
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      final isValid = await service.verifyMessageIntegrity(
        'encrypted:content',
        'user-2',
        'wrong-hmac',
      );

      expect(isValid, false);
    });

    test('verifyMessageIntegrity returns false on error', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('conversation_keys', builder);

      final isValid = await service.verifyMessageIntegrity(
        'encrypted:content',
        'user-2',
        'any-hmac',
      );

      expect(isValid, false);
    });
  });

  group('MessagingEncryptionService Private Methods Tests', () {
    test('sortAndConcatenate creates consistent conversation ID', () {
      final id1 = service.sortAndConcatenatePublic('user-1', 'user-2');
      final id2 = service.sortAndConcatenatePublic('user-2', 'user-1');

      expect(id1, id2);
      expect(id1, contains(':'));
    });

    test('generateConversationKey creates base64-encoded key', () {
      final key = service.generateConversationKeyPublic('conv-123');

      expect(key, isNotEmpty);
      expect(key.length, 32); // 32 characters for AES-256
    });

    test('generateConversationKey creates different keys for different IDs',
        () {
      final key1 = service.generateConversationKeyPublic('conv-1');
      final key2 = service.generateConversationKeyPublic('conv-2');

      expect(key1, isNot(key2));
    });

    test('calculateHmac returns consistent hash', () {
      final hmac1 = service.calculateHmacPublic('message', 'key');
      final hmac2 = service.calculateHmacPublic('message', 'key');

      expect(hmac1, hmac2);
    });

    test('calculateHmac returns different hashes for different messages', () {
      final hmac1 = service.calculateHmacPublic('message1', 'key');
      final hmac2 = service.calculateHmacPublic('message2', 'key');

      expect(hmac1, isNot(hmac2));
    });

    test('calculateHmac returns different hashes for different keys', () {
      final hmac1 = service.calculateHmacPublic('message', 'key1');
      final hmac2 = service.calculateHmacPublic('message', 'key2');

      expect(hmac1, isNot(hmac2));
    });
  });
}
