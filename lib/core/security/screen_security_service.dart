import 'dart:io';

import 'package:flutter/services.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Service responsible for preventing screenshots and screen recording.
///
/// It uses platform-specific mechanisms (like FLAG_SECURE on Android) to
/// protect sensitive screens from being captured or recorded by other apps
/// or the system itself.
class ScreenSecurityService {
  static const _channel = MethodChannel('com.verasso.app/screen_security');

  /// Protect the current screen from screenshots and recording.
  /// Note: Only works on Android. iOS requires native implementation.
  static Future<void> protectScreen() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('enableSecureFlag');
      } catch (e) {
        AppLogger.info('Error protecting screen: $e');
      }
    }
  }

  /// Remove protection from the current screen.
  static Future<void> unprotectScreen() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('disableSecureFlag');
      } catch (e) {
        AppLogger.info('Error unprotecting screen: $e');
      }
    }
  }
}
