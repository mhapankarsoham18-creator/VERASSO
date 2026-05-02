import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verasso/core/utils/file_validator.dart';

// A mock XFile that allows us to simulate file sizes and paths
class MockXFile extends XFile {
  final int simulatedLength;
  
  MockXFile(super.path, {required this.simulatedLength});
  
  @override
  Future<int> length() async => simulatedLength;
}

void main() {
  group('FileValidator Image Tests', () {
    test('Accepts valid image under 5MB', () async {
      final file = MockXFile('avatar.png', simulatedLength: 2 * 1024 * 1024); // 2 MB
      final error = await FileValidator.validateImage(file);
      expect(error, isNull);
    });

    test('Rejects image over 5MB limit', () async {
      final file = MockXFile('huge_avatar.jpg', simulatedLength: 6 * 1024 * 1024); // 6 MB
      final error = await FileValidator.validateImage(file);
      expect(error, contains('exceeds the 5MB size limit'));
    });

    test('Rejects invalid image extensions', () async {
      final file = MockXFile('malicious.exe', simulatedLength: 1 * 1024 * 1024);
      final error = await FileValidator.validateImage(file);
      expect(error, contains('Invalid image format'));
    });
  });

  group('FileValidator Video Tests', () {
    test('Accepts valid video under 50MB', () async {
      final file = MockXFile('clip.mp4', simulatedLength: 30 * 1024 * 1024); // 30 MB
      final error = await FileValidator.validateVideo(file);
      expect(error, isNull);
    });

    test('Rejects video over 50MB limit', () async {
      final file = MockXFile('movie.mp4', simulatedLength: 51 * 1024 * 1024); // 51 MB
      final error = await FileValidator.validateVideo(file);
      expect(error, contains('exceeds the 50MB size limit'));
    });

    test('Rejects invalid video extensions', () async {
      final file = MockXFile('document.pdf', simulatedLength: 5 * 1024 * 1024);
      final error = await FileValidator.validateVideo(file);
      expect(error, contains('Invalid video format'));
    });
  });
}
