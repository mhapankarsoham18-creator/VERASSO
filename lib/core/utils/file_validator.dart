import 'package:image_picker/image_picker.dart';

class FileValidator {
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50 MB

  static Future<String?> validateImage(XFile? file) async {
    if (file == null) return null;
    
    final length = await file.length();
    if (length > maxImageSizeBytes) {
      return 'Image exceeds the 5MB size limit. Please choose a smaller file.';
    }
    
    final extension = file.path.split('.').last.toLowerCase();
    const validExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    if (!validExtensions.contains(extension)) {
      return 'Invalid image format. Supported formats: JPG, PNG, WEBP, GIF.';
    }
    
    return null; // Null means valid
  }

  static Future<String?> validateVideo(XFile? file) async {
    if (file == null) return null;
    
    final length = await file.length();
    if (length > maxVideoSizeBytes) {
      return 'Video exceeds the 50MB size limit. Please choose a smaller file.';
    }
    
    final extension = file.path.split('.').last.toLowerCase();
    const validExtensions = ['mp4', 'mov', 'avi', 'mkv'];
    if (!validExtensions.contains(extension)) {
      return 'Invalid video format. Supported formats: MP4, MOV, AVI, MKV.';
    }
    
    return null; // Null means valid
  }
}
