import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/services/stories_service.dart';

/// Screen for creating a new user story
/// Allows camera capture, gallery selection, caption, and duration
/// A screen for creating and publishing new user stories.
class StoryCreationScreen extends StatefulWidget {
  /// Creates a [StoryCreationScreen].
  const StoryCreationScreen({super.key});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  final _storiesService = StoriesService();
  final _imagePicker = ImagePicker();
  final _captionController = TextEditingController();

  File? _selectedMedia;
  String _mediaType = 'image'; // 'image' or 'video'
  int _duration = 5; // Default 5 seconds
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _statusMessage = 'Uploading...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
        actions: [
          if (_selectedMedia != null && !_isUploading)
            TextButton.icon(
              onPressed: _publishStory,
              icon: const Icon(LucideIcons.send),
              label: const Text('Publish'),
            ),
        ],
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    '$_statusMessage ${(_uploadProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaPreview(),
                  const SizedBox(height: 16),

                  // Media selection buttons
                  if (_selectedMedia == null) ...[
                    const Text(
                      'Select Media',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _captureFromCamera,
                            icon: const Icon(LucideIcons.camera),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickFromGallery(false),
                            icon: const Icon(LucideIcons.image),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _recordVideo,
                        icon: const Icon(LucideIcons.video),
                        label: const Text('Record Video'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],

                  if (_selectedMedia != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Add Caption (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Display Duration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Duration:'),
                                Text(
                                  '$_duration seconds',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _duration.toDouble(),
                              min: 3,
                              max: 15,
                              divisions: 12,
                              label: '$_duration sec',
                              onChanged: (value) {
                                setState(() => _duration = value.toInt());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Widget _buildMediaPreview() {
    if (_selectedMedia == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No media selected',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _mediaType == 'image'
              ? Image.file(
                  _selectedMedia!,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 400,
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.playCircle,
                            size: 64, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'Video selected',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white),
            onPressed: () => setState(() => _selectedMedia = null),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedMedia = File(photo.path);
          _mediaType = 'image';
        });
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  Future<void> _pickFromGallery(bool isVideo) async {
    try {
      if (isVideo) {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 30),
        );

        if (video != null) {
          setState(() {
            _selectedMedia = File(video.path);
            _mediaType = 'video';
          });
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedMedia = File(image.path);
            _mediaType = 'image';
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick media: $e');
    }
  }

  // ... (dispose and other methods remain same, but I can't skip them easily with replace_file_content unless I target specific blocks)

  Future<void> _publishStory() async {
    if (_selectedMedia == null) {
      _showError('Please select a photo or video');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusMessage =
          _mediaType == 'video' ? 'Compressing video...' : 'Uploading...';
    });

    try {
      // Simulate upload progress
      // In a real app with compression, we might want to distinguish phases

      if (_mediaType == 'video') {
        setState(() => _statusMessage = 'Compressing Video...');
      } else {
        setState(() => _statusMessage = 'Uploading Image...');
        // Small mock progress for image as it's too fast usually
        for (int i = 0; i <= 90; i += 30) {
          if (!mounted) return;
          await Future.delayed(const Duration(milliseconds: 100));
          setState(() => _uploadProgress = i / 100);
        }
      }

      await _storiesService.createStory(
        mediaFile: _selectedMedia!,
        mediaType: _mediaType,
        caption: _captionController.text.trim(),
        duration: _duration,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
              if (progress > 0.99) _statusMessage = 'Finalizing...';
            });
          }
        },
      );

      setState(() {
        _uploadProgress = 1.0;
        _statusMessage = 'Complete!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story published successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _showError('Failed to publish story: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() {
          _selectedMedia = File(video.path);
          _mediaType = 'video';
        });
      }
    } catch (e) {
      _showError('Failed to record video: $e');
    }
  }

  // ... (build method needs update to use _statusMessage)

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
