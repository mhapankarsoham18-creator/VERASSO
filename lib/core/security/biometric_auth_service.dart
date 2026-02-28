import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [BiometricAuthService] instance.
final biometricAuthServiceProvider = Provider((ref) => BiometricAuthService());

/// Errors that can occur during biometric authentication
/// Errors that can occur during biometric authentication processes.
enum BiometricAuthError {
  /// General authentication failure.
  failed,

  /// Biometric hardware is not available on the device.
  notAvailable,

  /// Biometric authentication has not been enabled within the app settings.
  notEnabled,

  /// No biometric credentials (faces/fingerprints) are enrolled on the device.
  notEnrolled,

  /// The user is locked out due to too many failed attempts.
  lockedOut,

  /// The device does not have a passcode or PIN set.
  passcodeNotSet,

  /// An unknown or unhandled error occurred.
  unknown,
}

/// Represents the result of a biometric authentication attempt.
class BiometricAuthResult {
  /// Whether the authentication was successful.
  final bool success;

  /// The specific error type if [success] is false.
  final BiometricAuthError? error;

  /// A human-readable error message.
  final String? errorMessage;

  /// Creates an error result with a custom message.
  factory BiometricAuthResult.error(String? message) {
    return BiometricAuthResult._(
      success: false,
      error: BiometricAuthError.unknown,
      errorMessage: message ?? 'An unknown error occurred',
    );
  }

  /// Creates a generic failure result.
  factory BiometricAuthResult.failed() {
    return BiometricAuthResult._(
      success: false,
      error: BiometricAuthError.failed,
      errorMessage: 'Authentication failed',
    );
  }

  /// Creates a locked out error result.
  factory BiometricAuthResult.lockedOut() {
    return BiometricAuthResult._(
      success: false,
      error: BiometricAuthError.lockedOut,
      errorMessage:
          'Biometric authentication is locked due to too many failed attempts',
    );
  }

  /// Creates a "not available" error result.
  factory BiometricAuthResult.notAvailable() {
    return BiometricAuthResult._(
      success: false,
      error: BiometricAuthError.notAvailable,
      errorMessage: 'Biometric authentication is not available on this device',
    );
  }

  /// Creates a "not enabled" error result.
  factory BiometricAuthResult.notEnabled() {
    return BiometricAuthResult._(
      success: false,
      error: BiometricAuthError.notEnabled,
      errorMessage: 'Biometric authentication is not enabled',
    );
  }

  /// Creates a "not enrolled" error result.
  factory BiometricAuthResult.notEnrolled() {
    return BiometricAuthResult._(
      success: false,
      error: BiometricAuthError.notEnrolled,
      errorMessage:
          'No biometric credentials enrolled. Please set up Face ID or Fingerprint in device settings',
    );
  }

  /// Creates a "passcode not set" error result.
  factory BiometricAuthResult.passcodeNotSet() {
    return BiometricAuthResult._(
      success: false,
      error: BiometricAuthError.passcodeNotSet,
      errorMessage:
          'Device passcode is not set. Please set up a passcode first',
    );
  }

  /// Creates a successful authentication result.
  factory BiometricAuthResult.success() {
    return BiometricAuthResult._(success: true);
  }

  /// Internal constructor for [BiometricAuthResult].
  BiometricAuthResult._({
    required this.success,
    this.error,
    this.errorMessage,
  });
}

/// Service for biometric authentication (Face ID, Fingerprint, etc.)
class BiometricAuthService {
  static const String _biometricEnabledKey = 'biometric_auth_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Authenticate using biometrics
  /// Returns BiometricAuthResult with detailed status
  Future<BiometricAuthResult> authenticate({
    String reason = 'Please authenticate to access your account',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult.notAvailable();
      }

      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return BiometricAuthResult.notEnabled();
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
      );

      if (authenticated) {
        return BiometricAuthResult.success();
      } else {
        return BiometricAuthResult.failed();
      }
    } on PlatformException catch (e) {
      AppLogger.info('Biometric authentication error: $e');
      if (e.code == 'notAvailable') {
        return BiometricAuthResult.notAvailable();
      } else if (e.code == 'notEnrolled') {
        return BiometricAuthResult.notEnrolled();
      } else if (e.code == 'lockedOut' || e.code == 'permanentlyLockedOut') {
        return BiometricAuthResult.lockedOut();
      } else if (e.code == 'passcodeNotSet') {
        return BiometricAuthResult.passcodeNotSet();
      } else {
        return BiometricAuthResult.error(e.message);
      }
    } catch (e) {
      return BiometricAuthResult.error(e.toString());
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await _storage.write(key: _biometricEnabledKey, value: 'false');
  }

  /// Enable biometric authentication
  /// Returns true if successfully enabled (after verification)
  Future<bool> enableBiometric() async {
    try {
      // Verify biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception(
            'Biometric authentication not available on this device');
      }

      // Authenticate to confirm directly bypasses enabled check
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
      );

      if (!authenticated) {
        return false;
      }

      // Save preference
      await _storage.write(key: _biometricEnabledKey, value: 'true');
      return true;
    } catch (e) {
      AppLogger.info('Error enabling biometric: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      AppLogger.info('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Get user-friendly name for the primary biometric type
  Future<String> getBiometricTypeString() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'Biometric';
    }

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }

    if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }

    if (biometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    }

    return 'Biometric';
  }

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      AppLogger.info('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Check if biometric authentication is enabled in settings
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Stop biometric authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      AppLogger.info('Error stopping authentication: $e');
    }
  }
}
