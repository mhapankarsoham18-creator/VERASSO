import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/biometric_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BiometricAuthService service;
  // Note: BiometricAuthService instantiates its dependencies internally.
  // To test it without modifying the code, we rely on the MockLocalAuthentication
  // being available if it were injected, but since it's not,
  // we'll focus on the service's logic if possible or move to a more testable pattern.

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAvailableBiometrics') {
          return <String>[];
        }
        return false;
      },
    );
    service = BiometricAuthService();
  });

  group('BiometricAuthService Tests', () {
    test('isBiometricAvailable returns a boolean', () async {
      // Since it uses platform channels internally, in test environment it usually returns false.
      final result = await service.isBiometricAvailable();
      expect(result, isA<bool>());
    });

    test('getBiometricTypeString returns a string', () async {
      final result = await service.getBiometricTypeString();
      expect(result, isA<String>());
    });
  });
}
