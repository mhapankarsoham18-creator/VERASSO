import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/token_storage_service.dart';

import '../../mocks.dart';

void main() {
  late TokenStorageService service;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = TokenStorageService(storage: mockStorage);
  });

  group('TokenStorageService Tests', () {
    test('saveRefreshToken securely stores the token', () async {
      await service.saveRefreshToken('new-refresh-token');

      final stored = await service.getRefreshToken();
      expect(stored, equals('new-refresh-token'));
    });

    test('isSessionValid returns true for valid future expiry', () async {
      final futureExpiry = DateTime.now().add(const Duration(hours: 1));
      await service.saveSessionExpiry(futureExpiry);
      await service.saveRefreshToken('valid-token');

      final isValid = await service.isSessionValid();
      expect(isValid, isTrue);
    });

    test('isSessionValid returns false and clears tokens for passed expiry',
        () async {
      final pastExpiry = DateTime.now().subtract(const Duration(hours: 1));
      await service.saveSessionExpiry(pastExpiry);

      final isValid = await service.isSessionValid();
      expect(isValid, isFalse);

      final token = await service.getRefreshToken();
      expect(token, isNull);
    });

    test('clearTokens removes all authentication data', () async {
      await service.saveRefreshToken('token');
      await service.saveUserId('user-id');

      await service.clearTokens();

      expect(await service.getRefreshToken(), isNull);
      expect(await service.getUserId(), isNull);
    });
  });
}
