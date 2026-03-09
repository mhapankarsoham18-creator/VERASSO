import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/services/gemini_ai_service.dart';

class MockGeminiAIService extends Mock implements GeminiAIService {
  @override
  Future<String> sendMessage(String message, {String? systemPrompt}) =>
      super.noSuchMethod(
            Invocation.method(
              #sendMessage,
              [message],
              {#systemPrompt: systemPrompt},
            ),
            returnValue: Future.value('Mock Response'),
          )
          as Future<String>;
}

void main() {
  group('GeminiAIService Smoke Test', () {
    test('Service responds with placeholder when API key is missing', () async {
      final service = MockGeminiAIService();

      when(
        service.sendMessage('Hello'),
      ).thenAnswer((_) async => "Gemini AI is not configured");

      final response = await service.sendMessage('Hello');
      expect(response, contains('Gemini AI is not configured'));
    });
  });
}
