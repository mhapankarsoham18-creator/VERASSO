import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:math';

class SttState {
  final bool isListening;
  final String recognizedText;
  final double amplitude;

  SttState({
    this.isListening = false,
    this.recognizedText = '',
    this.amplitude = 0.0,
  });

  SttState copyWith({bool? isListening, String? recognizedText, double? amplitude}) {
    return SttState(
      isListening: isListening ?? this.isListening,
      recognizedText: recognizedText ?? this.recognizedText,
      amplitude: amplitude ?? this.amplitude,
    );
  }
}

class SttService extends Notifier<SttState> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  SttState build() {
    _initSpeech();
    return SttState();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          state = state.copyWith(isListening: false, amplitude: 0.0);
        }
      },
      onError: (errorNotification) {
        state = state.copyWith(isListening: false, amplitude: 0.0);
      },
    );
  }

  Future<void> startListening() async {
    if (!_speechEnabled) await _initSpeech();
    if (_speechEnabled) {
      state = state.copyWith(isListening: true, recognizedText: '', amplitude: 0.0);
      await _speechToText.listen(
        onResult: (result) {
          state = state.copyWith(recognizedText: result.recognizedWords);
        },
        onSoundLevelChange: (level) {
          // level is from -50 to 50 dB typically. Normalize it to 0.0 to 1.0
          double normalized = (level + 50) / 100;
          normalized = max(0.0, min(1.0, normalized));
          state = state.copyWith(amplitude: normalized);
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false, amplitude: 0.0);
  }
}

final sttServiceProvider = NotifierProvider<SttService, SttState>(() {
  return SttService();
});
