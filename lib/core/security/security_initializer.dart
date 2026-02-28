import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/secure_auth_service.dart';
import '../monitoring/app_logger.dart';
import 'biometric_auth_service.dart';
import 'encryption_service.dart';

/// Static coordinator responsible for initializing all security services on app startup.
///
/// This includes setting up encryption master keys, authentication services,
/// and biometric configurations. It should be initialized once in [main].
class SecurityInitializer {
  static EncryptionService? _encryptionService;
  static SecureAuthService? _authService;
  static BiometricAuthService? _biometricService;

  /// Get secure auth service instance
  static SecureAuthService get authService {
    if (_authService == null) {
      throw Exception(
          'Security services not initialized. Call SecurityInitializer.initialize() first.');
    }
    return _authService!;
  }

  /// Get biometric service instance
  static BiometricAuthService get biometricService {
    if (_biometricService == null) {
      throw Exception(
          'Security services not initialized. Call SecurityInitializer.initialize() first.');
    }
    return _biometricService!;
  }

  /// Get encryption service instance
  static EncryptionService get encryptionService {
    if (_encryptionService == null) {
      throw Exception(
          'Security services not initialized. Call SecurityInitializer.initialize() first.');
    }
    return _encryptionService!;
  }

  /// Check if services are initialized
  static bool get isInitialized =>
      _encryptionService != null &&
      _authService != null &&
      _biometricService != null;

  /// Initialize encryption and security services
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    try {
      AppLogger.debug('Initializing security services...');

      // Initialize encryption service
      _encryptionService = EncryptionService();
      await _encryptionService!.initialize();
      AppLogger.info('Encryption service initialized');

      // Initialize auth service
      final supabase = Supabase.instance.client;
      _authService = SecureAuthService(supabase);
      AppLogger.info('Secure auth service initialized');

      // Initialize biometric service (lightweight)
      _biometricService = BiometricAuthService();
      AppLogger.info('Biometric service initialized');

      AppLogger.info('All security services ready!');
    } catch (e) {
      AppLogger.critical('Failed to initialize security services', error: e);
      rethrow;
    }
  }
}

/// Example main.dart integration:
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize Supabase
///   await Supabase.initialize(
///     url: 'YOUR_SUPABASE_URL',
///     anonKey: 'YOUR_SUPABASE_ANON_KEY',
///   );
///   
///   // Initialize security services
///   await SecurityInitializer.initialize();
///   
///   runApp(const MyApp());
/// }
/// ```
