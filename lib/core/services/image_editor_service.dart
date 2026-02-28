import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:photofilters/photofilters.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Service providing image manipulation capabilities such as cropping and filtering.
class ImageEditorService {
  // Crop Image
  /// Opens a UI for the user to apply photographic filters to the [imageFile].
  static Future<File?> applyFilter(BuildContext context, File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      var image = img.decodeImage(imageFile.readAsBytesSync());

      if (image == null) return null;

      // This is a simplified way. Ideally we show a UI selector.
      // photofilters package usually requires pushing a new route.
      Map? imagefile = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoFilterSelector(
            title: const Text("Apply Filter"),
            image: image,
            filters: presetFiltersList,
            filename: fileName,
            loader: const Center(child: CircularProgressIndicator()),
            fit: BoxFit.contain,
          ),
        ),
      );

      if (imagefile != null && imagefile.containsKey('image_filtered')) {
        return imagefile['image_filtered'] as File;
      }
      return null;
    } catch (e) {
      AppLogger.info('Filter error: $e');
      return null;
    }
  }

  // Apply Filter
  /// Opens a UI for the user to crop the provided [imageFile].
  static Future<File?> cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      AppLogger.info('Crop error: $e');
      return null;
    }
  }
}
