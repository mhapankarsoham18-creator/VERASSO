import 'package:flutter/services.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Service for interacting with the system clipboard.
class ClipboardService {
  /// Copies the provided [text] to the system clipboard.
  static Future<void> copyToClipboard(String text,
      {String? successMessage}) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      AppLogger.info('Copied to clipboard');
    } catch (e) {
      AppLogger.error('Failed to copy to clipboard', error: e);
    }
  }
}
