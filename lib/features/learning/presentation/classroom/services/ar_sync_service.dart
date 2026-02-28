import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';

import '../../../../../core/services/bluetooth_mesh_service.dart';

/// Provider for the [ArSyncService] instance.
final arSyncServiceProvider =
    StateNotifierProvider<ArSyncService, ArExperimentState>((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return ArSyncService(mesh);
});

/// Represents the state of a synchronized AR experiment.
class ArExperimentState {
  /// Map of parameter names to their current values (e.g., pH, temperature).
  final Map<String, dynamic> parameters;

  /// Display name of the user who last modified the state.
  final String lastUpdatedBy;

  /// Timestamp of the last update.
  final DateTime timestamp;

  /// Creates an [ArExperimentState] instance.
  ArExperimentState({
    required this.parameters,
    required this.lastUpdatedBy,
    required this.timestamp,
  });

  /// Creates a copy of this state with updated fields.
  ArExperimentState copyWith({
    Map<String, dynamic>? parameters,
    String? lastUpdatedBy,
  }) {
    return ArExperimentState(
      parameters: parameters ?? this.parameters,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      timestamp: DateTime.now(),
    );
  }
}

/// Service responsible for synchronizing AR experiment parameters across the mesh network.
class ArSyncService extends StateNotifier<ArExperimentState> {
  final BluetoothMeshService _meshService;
  StreamSubscription? _meshSubscription;

  /// Sets up a new [ArSyncService] with the provided mesh service.
  ArSyncService(this._meshService)
      : super(ArExperimentState(
          parameters: {
            'temperature': 25.0,
            'phValue': 7.0,
            'mixingSpeed': 0.0,
            'isReactionActive': false,
            'modelTransform': {
              'position': [0.0, 0.0, 0.0],
              'rotation': [0.0, 0.0, 0.0],
              'scale': [1.0, 1.0, 1.0],
            },
          },
          lastUpdatedBy: 'System',
          timestamp: DateTime.now(),
        )) {
    _initListener();
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    super.dispose();
  }

  /// Updates the model transformation data and broadcasts it.
  void updateModelTransform({
    List<double>? position,
    List<double>? rotation,
    List<double>? scale,
  }) {
    final newParams = Map<String, dynamic>.from(state.parameters);
    final transform =
        Map<String, dynamic>.from(newParams['modelTransform'] ?? {});

    if (position != null) transform['position'] = position;
    if (rotation != null) transform['rotation'] = rotation;
    if (scale != null) transform['scale'] = scale;

    newParams['modelTransform'] = transform;
    state = state.copyWith(parameters: newParams, lastUpdatedBy: 'Me');

    _meshService.broadcastPacket(MeshPayloadType.scienceData, {
      'params': newParams,
      'action': 'transform_sync',
    });
  }

  /// Updates a specific parameter and broadcasts the change to the network.
  void updateParameter(String key, dynamic value) {
    // 1. Update Locally
    final newParams = Map<String, dynamic>.from(state.parameters);
    newParams[key] = value;
    state = state.copyWith(parameters: newParams, lastUpdatedBy: 'Me');

    // 2. Broadcast to Mesh
    _meshService.broadcastPacket(MeshPayloadType.scienceData, {
      'params': newParams,
      'key': key,
      'value': value,
    });
  }

  void _handleSyncPacket(MeshPacket packet) {
    final params = Map<String, dynamic>.from(packet.payload['params']);
    // Avoid feedback loops if needed, but MeshService handles deduplication
    state = ArExperimentState(
      parameters: params,
      lastUpdatedBy: packet.senderName,
      timestamp: DateTime.parse(packet.timestamp),
    );
  }

  void _initListener() {
    _meshSubscription = _meshService.meshStream.listen((packet) {
      if (packet.type == MeshPayloadType.scienceData) {
        _handleSyncPacket(packet);
      }
    });
  }
}
