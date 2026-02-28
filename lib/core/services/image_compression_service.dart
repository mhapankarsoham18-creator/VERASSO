import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Service for compressing and resizing images to optimize storage and upload.
class ImageCompressionService {
  /// Compress and resize image before upload
  /// Max dimensions: 1920x1080
  /// Max file size: 2MB
  static Future<File> compressImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large
      const maxWidth = 1920;
      const maxHeight = 1080;

      if (image.width > maxWidth || image.height > maxHeight) {
        // Calculate aspect ratio
        final aspectRatio = image.width / image.height;

        int newWidth;
        int newHeight;

        if (aspectRatio > 1) {
          // Landscape
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }

        image = img.copyResize(image, width: newWidth, height: newHeight);
      }

      // Compress to JPEG with quality 85
      final compressedBytes = img.encodeJpg(image, quality: 85);

      // If still too large, reduce quality
      List<int> finalBytes = compressedBytes;
      int quality = 85;

      while (finalBytes.length > 2 * 1024 * 1024 && quality > 50) {
        quality -= 10;
        finalBytes = img.encodeJpg(image, quality: quality);
      }

      // Write to temporary file
      final tempDir = await Directory.systemTemp.createTemp('verasso_');
      final compressedFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(finalBytes);

      AppLogger.info(
          'Image compressed: ${bytes.length} → ${finalBytes.length} bytes (${(finalBytes.length / bytes.length * 100).toStringAsFixed(1)}%)');

      return compressedFile;
    } catch (e, stack) {
      AppLogger.error('Image compression error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      // Return original file if compression fails
      return imageFile;
    }
  }

  /// Calculates the file size of the given [file] in Megabytes (MB).
  static Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }
}
