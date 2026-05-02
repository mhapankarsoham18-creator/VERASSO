import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/ira_theme_service.dart';
import '../services/stt_service.dart';
import '../services/study_buddy_service.dart';
import '../widgets/ira_character_widget.dart';
import '../widgets/vn_dialogue_box.dart';
import '../../../core/utils/file_validator.dart';

class IraConversationScreen extends ConsumerStatefulWidget {
  const IraConversationScreen({super.key});

  @override
  ConsumerState<IraConversationScreen> createState() => _IraConversationScreenState();
}

class _IraConversationScreenState extends ConsumerState<IraConversationScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  String _currentIraResponse = 'Hi! Ready to study? Tap the mic to talk to me, or upload a photo of your notes.';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Lock to landscape mode for the Visual Novel feel
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _textRecognizer.close();
    // Revert back to defaults when leaving the room
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(source: source);
    if (image == null) return;

    final validationError = await FileValidator.validateImage(image);
    if (validationError != null) {
      setState(() => _currentIraResponse = validationError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = recognizedText.text;
      if (extractedText.isEmpty) {
        setState(() {
          _currentIraResponse = "I couldn't read any text from that image. Can you try a clearer photo?";
          _isLoading = false;
        });
        return;
      }

      // Send to Ira
      final response = await ref.read(studyBuddyServiceProvider).getResponse("I uploaded notes. Text: $extractedText");
      setState(() {
        _currentIraResponse = response;
      });
    } catch (e) {
      setState(() {
        _currentIraResponse = "Oops, something went wrong reading the image.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMicPress(bool isListening) async {
    final stt = ref.read(sttServiceProvider.notifier);
    if (!isListening) {
      await stt.startListening();
    } else {
      await stt.stopListening();
      final text = ref.read(sttServiceProvider).recognizedText;
      if (text.isNotEmpty) {
        setState(() => _isLoading = true);
        final response = await ref.read(studyBuddyServiceProvider).getResponse(text);
        setState(() {
          _currentIraResponse = response;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(iraThemeServiceProvider);
    final sttState = ref.watch(sttServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Fallback dark background
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(
            child: Image.asset(
              themeState.backgroundPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(child: Text('Background Missing', style: TextStyle(color: Colors.white))),
            ),
          ),
          
          // Character Layer
          Positioned(
            bottom: 50, // Moved up to make space for dialogue box
            left: 0,
            right: 0,
            top: 0,
            child: IraCharacterWidget(
              expression: _isLoading ? 'Thinking' : 'Smile', 
              isTalking: !_isLoading
            ),
          ),

          // Dialogue Box Layer (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VnDialogueBox(
              text: _isLoading ? '...' : _currentIraResponse,
            ),
          ),

          // Custom Exit button (Top Left)
          Positioned(
            top: 24,
            left: 24,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // Action Buttons (Top Right)
          Positioned(
            top: 24,
            right: 24,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.camera_alt,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.photo_library,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),

          // Mic Button (Bottom Right)
          Positioned(
            bottom: 30,
            right: 24,
            child: GestureDetector(
              onTapDown: (_) => _handleMicPress(false),
              onTapUp: (_) => _handleMicPress(true),
              onTapCancel: () => _handleMicPress(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sttState.isListening ? Colors.redAccent : Colors.indigoAccent,
                  boxShadow: [
                    if (sttState.isListening)
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 20 * (1 + sttState.amplitude),
                        spreadRadius: 5 * (1 + sttState.amplitude),
                      )
                  ],
                ),
                child: Icon(
                  sttState.isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
