import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/pinned_http_client.dart';

void main() {
  group('PinnedHttpClient Tests', () {
    const String expectedHost = 'api.example.com';
    // SHA-256 of "test" = 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
    final Uint8List testCertDer = Uint8List.fromList('test'.codeUnits);
    const String validPin =
        '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
    final String otherPin = 'a' * 64;

    late FakeX509Certificate cert;

    setUp(() {
      cert = FakeX509Certificate(testCertDer);
    });

    test('validateCertificate returns true when pin matches', () {
      final isValid = PinnedHttpClient.validateCertificate(
        cert,
        expectedHost,
        443,
        expectedHost,
        [validPin],
      );

      expect(isValid, isTrue);
    });

    test('validateCertificate returns true when one of multiple pins matches',
        () {
      final isValid = PinnedHttpClient.validateCertificate(
        cert,
        expectedHost,
        443,
        expectedHost,
        [otherPin, validPin], // validPin is second
      );

      expect(isValid, isTrue);
    });

    test('validateCertificate returns false when pin does not match', () {
      final isValid = PinnedHttpClient.validateCertificate(
        cert,
        expectedHost,
        443,
        expectedHost,
        [otherPin],
      );

      expect(isValid, isFalse);
    });

    test('validateCertificate returns false when host does not match', () {
      final isValid = PinnedHttpClient.validateCertificate(
        cert,
        'malicious.com',
        443,
        expectedHost,
        [validPin],
      );

      expect(isValid, isFalse);
    });

    test('validateCertificate returns false when allowedShas is null or empty',
        () {
      expect(
        PinnedHttpClient.validateCertificate(
          cert,
          expectedHost,
          443,
          expectedHost,
          null,
        ),
        isFalse,
      );

      expect(
        PinnedHttpClient.validateCertificate(
          cert,
          expectedHost,
          443,
          expectedHost,
          [],
        ),
        isFalse,
      );
    });

    test('validateCertificate handles colon-separated pins', () {
      // 9f:86:...
      const String colonedPin =
          '9f:86:d0:81:88:4c:7d:65:9a:2f:ea:a0:c5:5a:d0:15:a3:bf:4f:1b:2b:0b:82:2c:d1:5d:6c:15:b0:f0:0a:08';

      final isValid = PinnedHttpClient.validateCertificate(
        cert,
        expectedHost,
        443,
        expectedHost,
        [colonedPin],
      );

      expect(isValid, isTrue);
    });
  });
}

// Create a fake certificate since X509Certificate is abstract
class FakeX509Certificate extends Fake implements X509Certificate {
  final Uint8List _der;

  FakeX509Certificate(this._der);

  @override
  Uint8List get der => _der;
}
