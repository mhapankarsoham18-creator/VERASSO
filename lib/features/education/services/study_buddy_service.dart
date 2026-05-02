
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/gamification_service.dart';
import 'voice_service.dart';
import 'local_ai_service.dart';
import 'package:verasso/core/utils/logger.dart';

final studyBuddyServiceProvider = Provider<StudyBuddyService>((ref) {
  return StudyBuddyService(ref);
});

class StudyBuddyService {
  final Ref ref;
  
  StudyBuddyService(this.ref);

  final List<Map<String, String>> _slidingWindowMemory = [];
  final int _maxWindowSize = 10;

  final String _v6ColloquialPrompt = '''
You are Ira, an elder sister and study buddy.
You speak using urban colloquial English, sprinkled with casual Hindi and Marathi words (Hinglish/Marathi).
Keep your tone encouraging, informal, and highly interactive.
Keep responses concise, usually 1-3 sentences.
Do not use formal robotic language.
''';

  Future<String> getResponse(String userText) async {
    // 1. Add to sliding window memory
    if (_slidingWindowMemory.isEmpty) {
       _slidingWindowMemory.add({'role': 'system', 'content': _v6ColloquialPrompt});
    }
    _slidingWindowMemory.add({'role': 'user', 'content': userText});
    if (_slidingWindowMemory.length > _maxWindowSize) {
      _slidingWindowMemory.removeAt(1); // Remove oldest user/assistant msg
    }

    // 2. Check connectivity — if offline, try local AI
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    String aiResponse = '';
    bool forceSystemVoice = false;

    if (isOffline) {
      // === OFFLINE MODE: Use local SLM ===
      appLogger.d('StudyBuddyService: Offline — routing to LocalAiService');
      final localAi = ref.read(localAiServiceProvider.notifier);
      aiResponse = await localAi.generateOfflineResponse(userText);
      forceSystemVoice = true; // System TTS for offline
      
      // Award Tier 3 XP for offline AI usage
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final profile = await Supabase.instance.client.from('profiles').select('id').eq('firebase_uid', uid).maybeSingle();
        if (profile != null) GamificationService().awardStudyXp(profile['id'], 3);
      }
    } else {
      // === ONLINE MODE: Tiered routing ===
      bool isShortMessage = userText.split(' ').length < 5;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      String? internalProfileId;
      if (uid != null) {
        final profile = await Supabase.instance.client.from('profiles').select('id').eq('firebase_uid', uid).maybeSingle();
        internalProfileId = profile?['id'];
      }

      // In production, this hits an edge function or Anthropic/OpenAI API directly.
      if (isShortMessage) {
        aiResponse = _getMockGreeting(userText);
        forceSystemVoice = false; // Try ElevenLabs for soul
        if (internalProfileId != null) GamificationService().awardStudyXp(internalProfileId, 1);
      } else {
        aiResponse = "Achha, let me explain this to you clearly. Basically, ${userText.substring(0, userText.length > 20 ? 20 : userText.length)} is straightforward. Samajh aagaya?";
        forceSystemVoice = true; // Use free system TTS for long explanations
        if (internalProfileId != null) GamificationService().awardStudyXp(internalProfileId, 2);
      }
    }

    // Add response to memory
    _slidingWindowMemory.add({'role': 'assistant', 'content': aiResponse});

    // 3. Play voice
    ref.read(voiceServiceProvider).speak(aiResponse, forceSystemVoice: forceSystemVoice);

    return aiResponse;
  }

  String _getMockGreeting(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('hi') || lower.contains('hello')) return 'Hey there! Kasa kay?';
    if (lower.contains('bye')) return 'Bye bye! See you soon.';
    if (lower.contains('thanks')) return 'Koi problem nahi, always here to help!';
    return 'Hmm, bolo na, what do you need help with?';
  }
}


