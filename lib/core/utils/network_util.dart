import 'package:network_info_plus/network_info_plus.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Utility for fetching network-related information.
class NetworkUtil {
  static final _info = NetworkInfo();

  /// Returns the current local IP address of the device.
  ///
  /// Returns null if the IP cannot be determined.
  static Future<String?> getIpAddress() async {
    try {
      final ip = await _info.getWifiIP();
      return ip;
    } catch (e, stack) {
      AppLogger.warning('Could not determine device IP', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }
}
