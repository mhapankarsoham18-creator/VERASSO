import 'dart:io';
import 'package:flutter/material.dart';
import 'package:verasso/core/widgets/verasso_snackbar.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../../core/validators/input_validator.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();
  bool _isTransmitting = false;
  bool _hasMath = false;
  File? _selectedMedia;
  String? _mediaType; // 'image' or 'video'

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia({required bool isVideo}) async {
    final XFile? file = isVideo 
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (file != null) {
      setState(() {
        _selectedMedia = File(file.path);
        _mediaType = isVideo ? 'video' : 'image';
      });
    }
  }

  Future<void> _captureMedia({required bool isVideo}) async {
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (file != null) {
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

      // Get Supabase Profile UUID from Firebase UID to resolve null operator error
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
        final fileName = '${DateTime.now().toIso8601String()}_${fbUser.uid}.$fileExt';
        
        await Supabase.instance.client.storage
            .from('feed_media')
            .upload(fileName, _selectedMedia!);
            
        mediaUrl = Supabase.instance.client.storage
            .from('feed_media')
            .getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('posts').insert({
        'author_id': authorId,
        'type': _mediaType ?? 'text',
        'content': sanitizedText,
        'has_math': _hasMath,
        if (mediaUrl != null) 'media_url': mediaUrl,
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transmission Error: $e')));
        setState(() => _isTransmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('TRANSMIT SIGNAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: NeoPixelBox(
                padding: 16,
                enableTilt: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: 'Enter coordinates or text...',
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (_selectedMedia != null) ...[
                      SizedBox(height: 16),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: context.colors.blockEdge, width: 2),
                          color: context.colors.shadowDark,
                        ),
                        child: Stack(
                          children: [
                            if (_mediaType == 'image')
                               Image.file(_selectedMedia!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            else 
                               Center(child: Icon(Icons.videocam, size: 48, color: context.colors.primary)),
                            Positioned(
                              top: 4, right: 4,
                              child: IconButton(
                                icon: Icon(Icons.close, color: context.colors.textPrimary, shadows: [Shadow(blurRadius: 2)]),
                                onPressed: () => setState(() { _selectedMedia = null; _mediaType = null; }),
                              )
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            // Has Math Toggle
            Row(
              children: [
                Checkbox(
                  value: _hasMath,
                  activeColor: context.colors.primary,
                  onChanged: (val) => setState(() => _hasMath = val ?? false),
                ),
                Text('Render as LaTeX Math', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            // Media picker row
            Row(
              children: [
                Expanded(
                  child: NeoPixelBox(
                    padding: 12,
                    isButton: true,
                    onTap: () => _pickMedia(isVideo: false),
                    child: Column(
                      children: [
                        Icon(Icons.image, color: context.colors.primary),
                        SizedBox(height: 4),
                        Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary, fontSize: 10))
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: NeoPixelBox(
                    padding: 12,
                    isButton: true,
                    onTap: () => _captureMedia(isVideo: false),
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt, color: context.colors.primary),
                        SizedBox(height: 4),
                        Text('Photo', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary, fontSize: 10))
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: NeoPixelBox(
                    padding: 12,
                    isButton: true,
                    onTap: () => _captureMedia(isVideo: true),
                    child: Column(
                      children: [
                        Icon(Icons.videocam, color: context.colors.primary),
                        SizedBox(height: 4),
                        Text('Record', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary, fontSize: 10))
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: NeoPixelBox(
                    padding: 12,
                    isButton: true,
                    onTap: () {
                      setState(() {
                        _mediaType = 'audio';
                      });
                      VerassoSnackbar.show(context, message: 'Voice recording will use device mic in Phase 3. Post tagged as audio.');
                    },
                    child: Column(
                      children: [
                        Icon(Icons.mic, color: _mediaType == 'audio' ? context.colors.accent : context.colors.primary),
                        SizedBox(height: 4),
                        Text('Voice', style: TextStyle(fontWeight: FontWeight.bold, color: _mediaType == 'audio' ? context.colors.accent : context.colors.primary, fontSize: 10))
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: NeoPixelBox(
                padding: 16,
                isButton: true,
                onTap: _isTransmitting ? null : _transmit,
                child: Center(
                  child: _isTransmitting 
                    ? VerassoLoading()
                    : Text('BROADCAST', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
