import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Service responsible for detecting if the device environment is compromised.
///
/// It checks for root access on Android and jailbreak status on iOS, as well
/// as developer mode settings, to ensure the app runs in a secure environment.
class MobileSecurityService {
  static final MobileSecurityService _instance =
      MobileSecurityService._internal();

  /// Returns the singleton instance of [MobileSecurityService].
  factory MobileSecurityService() {
    return _instance;
  }

  MobileSecurityService._internal();

  /// Check specifically for developer mode (USB debugging etc)
  Future<bool> isDeveloperModeEnabled() async {
    if (kIsWeb) return false;
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (e) {
      return false;
    }
  }

  /// Check if the device is compromised (rooted/jailbroken)
  Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false;

    try {
      bool jailbroken = await FlutterJailbreakDetection.jailbroken;

      // We might tolerate developer mode, but jailbreak/root is a risk
      return jailbroken;
    } catch (e) {
      // Logic fail-safe
      return false;
    }
  }
}
