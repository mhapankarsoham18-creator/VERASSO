import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/post_model.dart';
import 'feed_controller.dart';

/// A comprehensive screen for creating rich social posts (text, media, polls, audio).
class EnhancedCreatePostScreen extends ConsumerStatefulWidget {
  /// Creates a [EnhancedCreatePostScreen] instance.
  const EnhancedCreatePostScreen({super.key});

  @override
  ConsumerState<EnhancedCreatePostScreen> createState() =>
      _EnhancedCreatePostScreenState();
}

class _EnhancedCreatePostScreenState
    extends ConsumerState<EnhancedCreatePostScreen> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<File> _selectedMedia = [];
  PostType _postType = PostType.text;
  bool _isPersonal = false;

  // Poll fields
  final _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  // Audio
  late AudioRecorder _audioRecorder;
  String? _audioPath;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _post,
            child: const Text('Post',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Post type selector
              GlassContainer(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTypeButton(Icons.text_fields, 'Text', PostType.text),
                    _buildTypeButton(
                        LucideIcons.image, 'Media', PostType.media),
                    _buildTypeButton(
                        LucideIcons.barChart, 'Poll', PostType.poll),
                    _buildTypeButton(LucideIcons.mic, 'Audio', PostType.audio),
                  ],
                ),
              ),

              // Personal Visibility Toggle
              GlassContainer(
                margin: const EdgeInsets.only(bottom: 16),
                child: SwitchListTile(
                  title: const Text('Personal Post',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Only approved friends can see this',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  secondary: Icon(
                      _isPersonal ? LucideIcons.lock : LucideIcons.globe,
                      color: _isPersonal ? Colors.orange : Colors.blue),
                  value: _isPersonal,
                  onChanged: (val) => setState(() => _isPersonal = val),
                  activeThumbColor: Colors.orange,
                ),
              ),

              // Content area
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text input (always visible)
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.white54)),
                    ),

                    // Media preview
                    if (_selectedMedia.isNotEmpty) _buildMediaPreview(),

                    // Poll builder
                    if (_postType == PostType.poll) _buildPollCreator(),

                    // Audio recorder
                    if (_postType == PostType.audio) _buildAudioRecorder(),

                    const Divider(color: Colors.white24),

                    // Action buttons
                    Row(
                      children: [
                        IconButton(
                            onPressed: _pickMedia,
                            icon: const Icon(LucideIcons.image,
                                color: Colors.white)),
                        IconButton(
                            onPressed: _pickVideo,
                            icon: const Icon(LucideIcons.video,
                                color: Colors.white)),
                        IconButton(
                            onPressed: _createPoll,
                            icon: const Icon(LucideIcons.barChart,
                                color: Colors.white)),
                        IconButton(
                            onPressed: _toggleRecording,
                            icon: Icon(
                                _isRecording ? Icons.stop : LucideIcons.mic,
                                color:
                                    _isRecording ? Colors.red : Colors.white)),
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
  void dispose() {
    _contentController.dispose();
    _pollQuestionController.dispose();
    for (var controller in _pollOptionControllers) {
      controller.dispose();
    }
    _audioRecorder.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    // Initialize _isPersonal from user profile default setting if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        setState(() {
          _isPersonal = profile.defaultPersonalVisibility;
        });
      }
    });
  }

  void _addPollOption() {
    if (_pollOptionControllers.length < 4) {
      setState(() {
        _pollOptionControllers.add(TextEditingController());
      });
    }
  }

  Widget _buildAudioRecorder() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_isRecording ? Icons.mic : Icons.mic_off,
              color: _isRecording ? Colors.red : Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRecording ? 'Recording...' : 'Ready to record',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_isRecording || _recordingDuration > 0)
                  Text(
                    '${_isRecording ? 'Recording' : 'Recorded'}: ${_recordingDuration}s',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ),
          if (_isRecording)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedMedia.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedMedia[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedMedia.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_selectedMedia.length < 10)
          TextButton.icon(
            onPressed: _pickMedia,
            icon: const Icon(LucideIcons.plus),
            label: Text('Add more (${_selectedMedia.length}/10)'),
          ),
      ],
    );
  }

  Widget _buildPollCreator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Create a Poll',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _pollQuestionController,
          decoration: const InputDecoration(
            hintText: 'Ask a question...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_pollOptionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pollOptionControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Option ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_pollOptionControllers.length > 2)
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () =>
                        setState(() => _pollOptionControllers.removeAt(index)),
                  ),
              ],
            ),
          );
        }),
        if (_pollOptionControllers.length < 4)
          TextButton.icon(
            onPressed: _addPollOption,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add option'),
          ),
      ],
    );
  }

  Widget _buildTypeButton(IconData icon, String label, PostType type) {
    final isActive = (_postType == type && type != PostType.text) ||
        (type == PostType.text &&
            _postType == PostType.text &&
            _selectedMedia.isEmpty);

    return GestureDetector(
      onTap: () => setState(() => _postType = type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isActive ? Colors.blue : Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.blue : Colors.white70)),
        ],
      ),
    );
  }

  void _createPoll() {
    setState(() {
      _postType = PostType.poll;
    });
  }

  Future<void> _pickMedia() async {
    if (_selectedMedia.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 media files allowed')),
      );
      return;
    }

    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedMedia.addAll(
            images.map((x) => File(x.path)).take(10 - _selectedMedia.length));
        _postType = PostType.media;
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedMedia.add(File(video.path));
        _postType = PostType.media;
      });
    }
  }

  Future<void> _post() async {
    final content = _contentController.text.trim();
    if (content.isEmpty &&
        _selectedMedia.isEmpty &&
        _postType != PostType.poll &&
        _postType != PostType.audio) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final userId = user.id;

    try {
      await ref.read(feedProvider.notifier).createPost(
            userId: userId,
            content: content,
            images: _postType == PostType.media ? _selectedMedia : [],
            audio: _postType == PostType.audio && _audioPath != null
                ? File(_audioPath!)
                : null,
            isPersonal: _isPersonal,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moment Synced to Network')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _recordingDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordingDuration++);
    });
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        _timer?.cancel();
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final path =
              '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

          final config = RecordConfig();
          await _audioRecorder.start(config, path: path);

          _startTimer();
          setState(() {
            _isRecording = true;
            _postType = PostType.audio;
          });
        }
      }
    } catch (e) {
      AppLogger.warning('Recording error', error: e);
    }
  }
}
