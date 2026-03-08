import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:verasso/core/security/secure_config.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [GeminiAIService] instance.
final geminiAiServiceProvider = Provider<GeminiAIService>((ref) {
  return GeminiAIService();
});

/// Service that provides AI-powered assistance using Google's Gemini Pro.
class GeminiAIService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  void _init() {
    if (_isInitialized) return;
    
    final apiKey = SecureConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      AppLogger.warning('Gemini API Key is missing. AI features will be disabled.');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    _isInitialized = true;
  }

  /// Sends a message and gets a full response.
  Future<String> sendMessage(String message, {String? systemPrompt}) async {
    _init();
    if (!_isInitialized) return "Gemini AI is not configured. Please add an API key.";

    try {
      final content = [
        if (systemPrompt != null) Content.system(systemPrompt),
        Content.text(message),
      ];

      final response = await _model.generateContent(content);
      return response.text ?? "No response from Gemini.";
    } catch (e) {
      AppLogger.error('Gemini SDK Error', error: e);
      return "I encountered an error while processing your request. Please try again later.";
    }
  }

  /// Streams the AI response for better UX.
  Stream<String> streamMessage(String message, {String? systemPrompt}) async* {
    _init();
    if (!_isInitialized) {
      yield "Gemini AI is not configured.";
      return;
    }

    try {
      final content = [
        if (systemPrompt != null) Content.system(systemPrompt),
        Content.text(message),
      ];

      final responseStream = _model.generateContentStream(content);
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      AppLogger.error('Gemini SDK Stream Error', error: e);
      yield "An error occurred during streaming.";
    }
  }
}
