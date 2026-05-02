import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:verasso/core/utils/logger.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

class VoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _systemTts = FlutterTts();
  
  // Get keys from .env
  String get _elevenLabsApiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  String get _elevenLabsVoiceId => dotenv.env['ELEVENLABS_VOICE_ID'] ?? '';

  bool _isSystemTtsInitialized = false;

  VoiceService() {
    _initSystemTts();
  }

  Future<void> _initSystemTts() async {
    await _systemTts.setLanguage("en-IN");
    await _systemTts.setSpeechRate(0.5);
    await _systemTts.setVolume(1.0);
    await _systemTts.setPitch(1.1); // Slightly higher pitch for 'sister' vibe
    _isSystemTtsInitialized = true;
  }

  /// Normalizes string to increase cache hit rate
  String _normalizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  /// Generates a SHA-256 hash to use as an MP3 filename
  String _generateHash(String text) {
    final normalized = _normalizeText(text);
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  /// Plays audio. Tries to use Cache -> ElevenLabs -> Fallback to System TTS.
  /// Set [forceSystemVoice] to true for long study explanations (saving tokens).
  Future<void> speak(String text, {bool forceSystemVoice = false}) async {
    if (text.isEmpty) return;

    // 1. Check if we should use the free System Voice for big text
    if (forceSystemVoice || _elevenLabsApiKey.isEmpty || _elevenLabsApiKey == 'your_api_key_here') {
      appLogger.d("VoiceService: Using System TTS Fallback.");
      await _playSystemTts(text);
      return;
    }

    try {
      // 2. Check Cache
      final hash = _generateHash(text);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ira_voice_cache_$hash.mp3');

      if (await file.exists()) {
        appLogger.d("VoiceService: Playing from Cache! (0 Tokens Burned)");
        await _audioPlayer.setFilePath(file.path);
        await _audioPlayer.play();
        return;
      }

      // 3. Fallback to ElevenLabs API Online Call
      appLogger.d("VoiceService: Calling ElevenLabs API...");
      final audioBytes = await _fetchElevenLabsAudio(text);
      
      if (audioBytes != null) {
        // Save to cache for next time
        await file.writeAsBytes(audioBytes);
        await _audioPlayer.setFilePath(file.path);
        await _audioPlayer.play();
      } else {
        // If API fails (e.g. out of credits), fallback to System TTS safely
        await _playSystemTts(text);
      }

    } catch (e) {
      appLogger.d("VoiceService Error: $e");
      await _playSystemTts(text); // Ultimate safe fallback
    }
  }

  Future<Uint8List?> _fetchElevenLabsAudio(String text) async {
    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$_elevenLabsVoiceId');
    
    final response = await http.post(
      url,
      headers: {
        'xi-api-key': _elevenLabsApiKey,
        'Content-Type': 'application/json',
        'accept': 'audio/mpeg',
      },
      body: jsonEncode({
        "text": text,
        "model_id": "eleven_monolingual_v1",
        "voice_settings": {
          "stability": 0.5,
          "similarity_boost": 0.75
        }
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      appLogger.d("ElevenLabs API failed with status ${response.statusCode}: ${response.body}");
      return null;
    }
  }

  Future<void> _playSystemTts(String text) async {
    if (!_isSystemTtsInitialized) await _initSystemTts();
    await _systemTts.speak(text);
  }

  void stop() {
    _audioPlayer.stop();
    _systemTts.stop();
  }
}

