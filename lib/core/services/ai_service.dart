import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'gemini_ai_service.dart';

/// Provider for the [AIService] instance.
final aiServiceProvider = Provider<AIService>((ref) {
  final gemini = ref.watch(geminiAiServiceProvider);
  return AIService(gemini);
});

/// Service that provides AI-powered learning assistance and guidance via Google Gemini.
///
/// It uses "Cosmos AI", the platform's AI tutor (Beta).
class AIService {
  final GeminiAIService _gemini;

  /// Creates an [AIService] with a [gemini] service.
  AIService(this._gemini);

  static const String _systemPrompt =
      'You are Cosmos AI (Beta), a helpful AI learning assistant for the Verasso platform. Your goal is to guide students in their learning journey.';

  /// Sends a message to the AI and retrieves a response via Gemini.
  Future<String> sendMessage(String userMessage) async {
    try {
      return await _gemini.sendMessage(userMessage, systemPrompt: _systemPrompt);
    } catch (e) {
      AppLogger.error('AIService Exception', error: e);
      return "Cosmos AI service interrupted. Please check your network connection.";
    }
  }

  /// Streams the AI response from Gemini.
  Stream<String> streamMessage(String userMessage) {
    return _gemini.streamMessage(userMessage, systemPrompt: _systemPrompt);
  }
}
