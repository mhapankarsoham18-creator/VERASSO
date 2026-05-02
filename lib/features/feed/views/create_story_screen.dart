import 'dart:io';
import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../../core/validators/input_validator.dart';
import '../../../core/utils/file_validator.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _textController = TextEditingController();
  bool _isTransmitting = false;
  File? _selectedMedia;
  String? _mediaType; // 'image' or 'video'

  final ImagePicker _picker = ImagePicker();

  Future<void> _captureMedia({required bool isVideo}) async {
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (file != null) {
      final error = isVideo
          ? await FileValidator.validateVideo(file)
          : await FileValidator.validateImage(file);
      if (error != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      setState(() {
        _selectedMedia = File(file.path);
        _mediaType = isVideo ? 'video' : 'image';
      });
    }
  }

  void _transmit() async {
    final rawText = _textController.text;
    if (rawText.isEmpty && _selectedMedia == null) return;
    
    final validationError = InputValidator.validatePost(rawText);
    if (validationError != null && rawText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    
    final sanitizedText = InputValidator.sanitize(rawText);

    setState(() => _isTransmitting = true);

    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) throw 'Not authenticated safely.';

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('firebase_uid', fbUser.uid)
          .maybeSingle();

      if (profileResponse == null) {
         throw 'Identity Profile not found in database. Broadcast failed.';
      }
      final authorId = profileResponse['id'];

      String? mediaUrl;
      if (_selectedMedia != null) {
        final fileExt = _selectedMedia!.path.split('.').last;
        final fileName = 'story_${const Uuid().v4()}.$fileExt';
        
        await Supabase.instance.client.storage
            .from('feed_media')
            .upload(fileName, _selectedMedia!);
            
        mediaUrl = Supabase.instance.client.storage
            .from('feed_media')
            .getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('stories').insert({
        'author_id': authorId,
        'media_url': mediaUrl,
        'media_type': _mediaType ?? 'text',
        'content': sanitizedText.isEmpty ? null : sanitizedText,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isTransmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transmission failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('NEW STORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          if (_isTransmitting)
            Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: VerassoLoading()))
          else
            TextButton(
              onPressed: _transmit,
              child: Text('POST', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            NeoPixelBox(
              padding: 16,
              child: TextField(
                controller: _textController,
                maxLines: 4,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add a caption or text story...',
                  hintStyle: TextStyle(color: context.colors.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_selectedMedia != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.blockEdge, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _mediaType == 'video'
                      ? Center(child: Icon(Icons.play_circle_fill, size: 64, color: context.colors.primary))
                      : Image.file(_selectedMedia!, fit: BoxFit.cover),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: context.colors.error, size: 32),
                    onPressed: () => setState(() { _selectedMedia = null; _mediaType = null; }),
                  )
                ],
              ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBox(Icons.camera_alt, 'Photo', () => _captureMedia(isVideo: false)),
                _buildActionBox(Icons.videocam, 'Video', () => _captureMedia(isVideo: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBox(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: NeoPixelBox(
          padding: 16,
          isButton: true,
          onTap: onTap,
          child: Column(
            children: [
              Icon(icon, size: 32, color: context.colors.primary),
              SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
