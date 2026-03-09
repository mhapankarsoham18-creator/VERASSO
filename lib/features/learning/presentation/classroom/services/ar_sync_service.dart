import 'package:flutter_riverpod/legacy.dart';

/// No-op provider for AR Sync Service.
final arSyncServiceProvider =
    StateNotifierProvider<ArSyncService, ArExperimentState>((ref) {
      return ArSyncService();
    });

/// No-op implementation of AR Sync Service.
class ArSyncService extends StateNotifier<ArExperimentState> {
  ArSyncService() : super(ArExperimentState());
  void updateParameter(String key, dynamic value) {}
}

/// No-op state class for AR experiments.
class ArExperimentState {
  final String lastUpdatedBy = 'System';
  final Map<String, dynamic> parameters = {
    'temperature': 25.0,
    'phValue': 7.0,
    'mixingSpeed': 0.0,
    'isReactionActive': false,
  };
}
