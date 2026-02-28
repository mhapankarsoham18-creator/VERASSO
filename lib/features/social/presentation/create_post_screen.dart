import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart' as cni;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/services/image_editor_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/post_model.dart';
import 'feed_controller.dart';

/// Legacy post composer used before [EnhancedCreatePostScreen].
///
/// Kept for backwards compatibility and simple edit flows; new entry points
/// should prefer the enhanced composer.
@Deprecated('Use EnhancedCreatePostScreen for the main posting flow.')
class CreatePostScreen extends ConsumerStatefulWidget {
  /// The post to be edited, if any.
  final Post? postToEdit;

  /// Creates a [CreatePostScreen] instance.
  const CreatePostScreen({super.key, this.postToEdit});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

// ignore: deprecated_member_use_from_same_package
class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  File? _selectedImage;
  // If editing, we might have an existing URL
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.postToEdit != null ? 'Edit Post' : 'New Post'),
        actions: [
          TextButton(
            onPressed: feedState.isLoading ? null : _post,
            child: feedState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.postToEdit != null ? 'Update' : 'Post',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.white54)),
                    ),
                    if (_existingImageUrl != null && _selectedImage == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: cni.CachedNetworkImage(
                              imageUrl: _existingImageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                      ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_selectedImage!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: IconButton(
                                    icon: const Icon(LucideIcons.x,
                                        color: Colors.white),
                                    onPressed: () =>
                                        setState(() => _selectedImage = null),
                                    style: IconButton.styleFrom(
                                        backgroundColor: Colors.black
                                            .withValues(alpha: 0.54)),
                                  ),
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: _cropImage,
                                  icon: const Icon(LucideIcons.crop,
                                      size: 16, color: Colors.white),
                                  label: const Text('Crop',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                TextButton.icon(
                                  onPressed: _applyFilter,
                                  icon: const Icon(LucideIcons.palette,
                                      size: 16, color: Colors.white),
                                  label: const Text('Filters',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const Divider(color: Colors.white24),
                    Row(
                      children: [
                        IconButton(
                            onPressed: _pickImage,
                            icon: const Icon(LucideIcons.image,
                                color: Colors.white)),
                        IconButton(
                            onPressed: _pickVideo,
                            icon: const Icon(LucideIcons.video,
                                color: Colors.white)),
                        IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Audio recording feature coming soon')));
                            },
                            icon: const Icon(LucideIcons.mic,
                                color: Colors.white)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _contentController.text = widget.postToEdit!.content ?? '';
      if (widget.postToEdit!.mediaUrls.isNotEmpty) {
        _existingImageUrl = widget.postToEdit!.mediaUrls.first;
      }
    }
  }

  Future<void> _applyFilter() async {
    if (_selectedImage == null) return;
    final filtered =
        await ImageEditorService.applyFilter(context, _selectedImage!);
    if (filtered != null) {
      setState(() => _selectedImage = filtered);
    }
  }

  Future<void> _cropImage() async {
    if (_selectedImage == null) return;
    final cropped = await ImageEditorService.cropImage(_selectedImage!);
    if (cropped != null) {
      setState(() => _selectedImage = cropped);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Offer to edit immediately or just set it
      // For UX, just set it, then show edit buttons on the preview
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Video processing...')));
      // Ideally set a _selectedVideo file and update preview
    }
  }

  Future<void> _post() async {
    final content = _contentController.text.trim();
    if (content.isEmpty &&
        _selectedImage == null &&
        _existingImageUrl == null) {
      return;
    }

    if (widget.postToEdit != null) {
      // Editing
      await ref.read(feedProvider.notifier).updatePost(
            postId: widget.postToEdit!.id,
            content: content,
          );
    } else {
      // Creating
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      await ref.read(feedProvider.notifier).createPost(
            userId: user.id,
            content: content,
            images: _selectedImage != null ? [_selectedImage!] : [],
          );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
