import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../../../core/services/app_lifecycle_guard.dart';
import 'package:verasso/core/utils/logger.dart';

final localAiServiceProvider =
    NotifierProvider<LocalAiService, LocalAiState>(() => LocalAiService());

/// Tracks the download and readiness state of the local SLM.
class LocalAiState {
  final bool isModelDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final String? modelPath;
  final String selectedModelId;
  final bool isModelLoaded;

  LocalAiState({
    this.isModelDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.modelPath,
    this.selectedModelId = 'phi3-mini',
    this.isModelLoaded = false,
  });

  LocalAiState copyWith({
    bool? isModelDownloaded,
    bool? isDownloading,
    double? downloadProgress,
    String? modelPath,
    String? selectedModelId,
    bool? isModelLoaded,
  }) {
    return LocalAiState(
      isModelDownloaded: isModelDownloaded ?? this.isModelDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      modelPath: modelPath ?? this.modelPath,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      isModelLoaded: isModelLoaded ?? this.isModelLoaded,
    );
  }
}

/// Available models for offline inference, tiered by device RAM.
class OfflineModel {
  final String id;
  final String name;
  final String description;
  final String downloadUrl;
  final int sizeBytes;
  final int minRamGb;

  const OfflineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.minRamGb,
  });
}

class LocalAiService extends Notifier<LocalAiState> implements LifecycleAwareService {
  static const List<OfflineModel> availableModels = [
    OfflineModel(
      id: 'phi1.5',
      name: 'Phi-1.5 (Q4)',
      description: 'Ultra-fast for low-end devices (2GB RAM). Quick answers.',
      downloadUrl: 'https://huggingface.co/microsoft/phi-1_5/resolve/main/phi-1_5-q4_k_m.gguf',
      sizeBytes: 850000000,
      minRamGb: 2,
    ),
    OfflineModel(
      id: 'phi3-mini',
      name: 'Phi-3 Mini (Q4)',
      description: 'Optimized for budget phones (4-6GB RAM). Fast inference.',
      downloadUrl: 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf',
      sizeBytes: 2390000000,
      minRamGb: 4,
    ),
    OfflineModel(
      id: 'llama3-8b',
      name: 'Llama 3 8B (Q4)',
      description: 'Smartest offline model. Requires 8GB+ RAM.',
      downloadUrl: 'https://huggingface.co/QuantFactory/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct.Q4_K_M.gguf',
      sizeBytes: 4920000000,
      minRamGb: 8,
    ),
  ];

  LlamaParent? _llamaParent;
  Completer<void>? _initCompleter;
  
  Timer? _inactivityTimer;
  static const int _autoUnloadMinutes = 5;

  @override
  LocalAiState build() {
    _checkExistingModel();
    AppLifecycleGuard.instance.registerService(this);
    ref.onDispose(() {
      AppLifecycleGuard.instance.unregisterService(this);
      _llamaParent?.dispose();
    });
    return LocalAiState();
  }

  Future<void> _checkExistingModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/ira_offline_model.gguf');
    if (await modelFile.exists()) {
      state = state.copyWith(
        isModelDownloaded: true,
        modelPath: modelFile.path,
      );
    }
  }

  void selectModel(String modelId) {
    if (state.selectedModelId != modelId) {
      state = state.copyWith(selectedModelId: modelId);
      // If we switch models and one is loaded, we should probably unload it
      _unloadModel();
    }
  }

  void _unloadModel() {
    _inactivityTimer?.cancel();
    _llamaParent?.dispose();
    _llamaParent = null;
    _initCompleter = null;
    state = state.copyWith(isModelLoaded: false);
  }

  // ===== LIFECYCLE MANAGEMENT =====

  @override
  void onAppBackgrounded() {
    if (state.isModelLoaded) {
      appLogger.d('LocalAiService: App backgrounded. Unloading AI model to save battery.');
      _unloadModel();
    }
  }

  @override
  void onAppResumed() {
    // Lazy load on next prompt, no action needed here.
  }

  Future<void> downloadModel() async {
    final model = availableModels.firstWhere(
      (m) => m.id == state.selectedModelId,
      orElse: () => availableModels.first,
    );

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelFile = File('${dir.path}/ira_offline_model.gguf');

      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? model.sizeBytes;

      int receivedBytes = 0;
      final sink = modelFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        state = state.copyWith(
          downloadProgress: receivedBytes / totalBytes,
        );
      }

      await sink.close();

      state = state.copyWith(
        isModelDownloaded: true,
        isDownloading: false,
        downloadProgress: 1.0,
        modelPath: modelFile.path,
      );
    } catch (e) {
      appLogger.d('LocalAiService: Download failed: $e');
      state = state.copyWith(isDownloading: false, downloadProgress: 0.0);
    }
  }

  Future<void> deleteModel() async {
    _unloadModel();
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/ira_offline_model.gguf');
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
    state = LocalAiState(selectedModelId: state.selectedModelId);
  }

  Future<void> _initModel() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    if (state.modelPath == null) {
      _initCompleter!.complete();
      return;
    }

    try {
      final loadCommand = LlamaLoad(
        path: state.modelPath!,
        modelParams: ModelParams(),
        contextParams: ContextParams(),
        samplingParams: SamplerParams(),
      );

      _llamaParent = LlamaParent(loadCommand);
      await _llamaParent!.init();
      
      state = state.copyWith(isModelLoaded: true);
      _initCompleter!.complete();
    } catch (e) {
      appLogger.d('LocalAiService: Model init failed: $e');
      _initCompleter!.completeError(e);
      _initCompleter = null;
    }
  }

  /// Generates a response using the local SLM.
  Future<String> generateOfflineResponse(String prompt) async {
    if (!state.isModelDownloaded || state.modelPath == null) {
      return 'Offline model not downloaded yet. Go to Settings > Offline Brain to download.';
    }

    if (!state.isModelLoaded) {
      await _initModel();
    }

    if (_llamaParent == null) {
      return 'Failed to load the offline brain. Please check device RAM.';
    }

    final completer = Completer<String>();
    String buffer = '';
    
    // Select the correct prompt template
    String formattedPrompt = '';
    switch (state.selectedModelId) {
      case 'phi1.5':
        formattedPrompt = 'User: $prompt\nAssistant:';
        break;
      case 'phi3-mini':
        formattedPrompt = '<|system|>\nYou are Ira, a friendly study buddy. Keep it colloquial.<|end|>\n<|user|>\n$prompt<|end|>\n<|assistant|>\n';
        break;
      case 'llama3-8b':
        formattedPrompt = '<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\nYou are Ira, a friendly study buddy. Keep it colloquial.<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n$prompt<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n';
        break;
      default:
        formattedPrompt = prompt;
    }

    final subscription = _llamaParent!.stream.listen((token) {
      buffer += token;
    }, onDone: () {
      completer.complete(buffer.trim());
    }, onError: (e) {
      completer.completeError(e);
    });

    _llamaParent!.sendPrompt(formattedPrompt);

    try {
      final result = await completer.future.timeout(const Duration(minutes: 2));
      _resetInactivityTimer();
      return result;
    } catch (e) {
      subscription.cancel();
      return 'The offline brain is taking too long to think. Maybe try a shorter question?';
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: _autoUnloadMinutes), () {
      appLogger.d('LocalAiService: Auto-unloaded model after $_autoUnloadMinutes min inactivity');
      _unloadModel();
    });
  }
}



