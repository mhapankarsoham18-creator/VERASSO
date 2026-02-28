import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verasso/core/security/offline_security_service.dart';

void main() {
  late OfflineSecurityService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = OfflineSecurityService();
  });

  group('OfflineSecurityService Tests', () {
    test('setIdentityHint stores email and hint flag', () async {
      await service.setIdentityHint('test@example.com');

      expect(await service.hasIdentityHint(), isTrue);
      expect(await service.getLastKnownEmail(), equals('test@example.com'));
    });

    test('clearIdentityHint removes all data', () async {
      await service.setIdentityHint('test@example.com');
      await service.clearIdentityHint();

      expect(await service.hasIdentityHint(), isFalse);
      expect(await service.getLastKnownEmail(), isNull);
    });

    test('hasIdentityHint returns false by default', () async {
      expect(await service.hasIdentityHint(), isFalse);
    });
  });
}
