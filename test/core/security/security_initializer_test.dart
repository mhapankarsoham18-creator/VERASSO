import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/security/security_initializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock SharedPreferences channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      },
    );

    // Mock SecureStorage channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (methodCall) async {
        if (methodCall.method == 'read') {
          return null;
        }
        if (methodCall.method == 'write') {
          return null;
        }
        return null;
      },
    );
  });

  group('SecurityInitializer Tests', () {
    test('isInitialized should be false before initialization', () {
      expect(SecurityInitializer.isInitialized, isFalse);
    });

    test('accessing services before initialization should throw', () {
      expect(() => SecurityInitializer.authService, throwsException);
      expect(() => SecurityInitializer.biometricService, throwsException);
      expect(() => SecurityInitializer.encryptionService, throwsException);
    });

    test('initialize should set up all services', () async {
      // Initialize Supabase first as SecurityInitializer depends on it
      try {
        await Supabase.initialize(
          url: 'https://test.supabase.co',
          anonKey: 'test-key',
        );
      } catch (e) {
        // May already be initialized
      }

      await SecurityInitializer.initialize();

      expect(SecurityInitializer.isInitialized, isTrue);
      expect(SecurityInitializer.authService, isNotNull);
      expect(SecurityInitializer.biometricService, isNotNull);
      expect(SecurityInitializer.encryptionService, isNotNull);
    });
    group('SecurityInitializer Regression Test', () {
      test(
          'Initialization should succeed even if Supabase is already configured',
          () async {
        await SecurityInitializer.initialize();
        expect(SecurityInitializer.isInitialized, isTrue);
      });
    });
  });
}
