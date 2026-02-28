import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [AIService] instance.
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Service that provides AI-powered learning assistance and guidance via OpenRouter.
///
/// It uses "Cosmos AI", the platform's AI tutor (Beta).
class AIService {
  static const String _model = 'openai/gpt-4o-mini';
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Sends a message to the AI and retrieves a response via OpenRouter.
  Future<String> sendMessage(String userMessage) async {
    try {
      // 1. Load API Key from .env
      final envFile = File('.env');
      if (!await envFile.exists()) {
        throw Exception('.env file not found');
      }

      final envContent = await envFile.readAsString();
      final lines = envContent.split('\n');

      String apiKey = '';
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('OPENAI_API_KEY=')) {
          apiKey = trimmed
              .split('=')[1]
              .trim()
              .replaceAll('"', '')
              .replaceAll("'", '');
          break;
        }
      }

      if (apiKey.isEmpty) {
        throw Exception('OpenRouter API Key is missing in .env');
      }

      // 2. Call OpenRouter API
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://verasso.app', // Required by OpenRouter
              'X-Title': 'Verasso', // Optional but recommended
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are Cosmos AI (Beta), a helpful AI learning assistant for the Verasso platform. Your goal is to guide students in their learning journey.'
                },
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        final error = jsonDecode(response.body);
        final message = error['error']?['message'] ?? 'Unknown error';
        AppLogger.warning('OpenRouter Service Error: $message');
        return "Cosmos AI is currently unavailable (API Error). Please contact support or try again later.";
      }
    } catch (e) {
      AppLogger.error('AIService Exception', error: e);
      return "Cosmos AI service interrupted. Please check your network connection.";
    }
  }
}
