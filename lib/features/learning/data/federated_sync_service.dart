import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';

import '../../../core/mesh/models/mesh_packet.dart';

/// Provides a shared [FederatedSyncService] for curriculum preference syncing.
final federatedSyncServiceProvider = Provider<FederatedSyncService>((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return FederatedSyncService(mesh);
});

/// Data Transfer Object for curriculum category weights.
class CurriculumWeights {
  /// Mapping of category names to their respective interest weights.
  final Map<String, double> scores;

  /// Creates a [CurriculumWeights] instance.
  CurriculumWeights(this.scores);

  /// Creates a [CurriculumWeights] from a JSON-compatible map.
  factory CurriculumWeights.fromJson(Map<String, dynamic> json) {
    return CurriculumWeights(
      Map<String, double>.from(json['scores'] ?? {}),
    );
  }

  /// Converts the [CurriculumWeights] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'scores': scores};
}

/// Service that performs lightweight federated averaging of curriculum interests across the mesh network.
class FederatedSyncService {
  final BluetoothMeshService _meshService;
  final Map<String, double> _localWeights = {
    'science': 0.5,
    'humanities': 0.5,
    'finance': 0.5,
    'technology': 0.5,
  };

  StreamSubscription? _meshSubscription;

  /// Creates a [FederatedSyncService] and starts listening for mesh deltas.
  FederatedSyncService(this._meshService) {
    _init();
  }

  /// The date and time when the service was initialized.
  /// Returns an immutable view of locally refined curriculum weights.
  Map<String, double> get refinedWeights => Map.unmodifiable(_localWeights);

  /// Cancels mesh subscriptions and stops federated syncing.
  void dispose() {
    _meshSubscription?.cancel();
  }

  /// Applies a local [focus] update for the given [category] in `[0, 1]`.
  void updateInterests(String category, double focus) {
    if (_localWeights.containsKey(category)) {
      _localWeights[category] =
          (_localWeights[category]! + focus).clamp(0.0, 1.0);
    }
  }

  void _broadcastLocalDelta() {
    AppLogger.info('Federated Learning: Broadcasting curriculum deltas');
    _meshService.broadcastPacket(
      MeshPayloadType.federatedDelta,
      _localWeights,
    );
  }

  void _handleIncomingDelta(MeshPacket packet) {
    final incomingWeights = CurriculumWeights.fromJson(packet.payload);

    // Simple Federated Averaging (Stochastic approximation)
    // We adjust local weights slightly towards the neighborhood average (momentum: 0.05)
    for (var entry in incomingWeights.scores.entries) {
      if (_localWeights.containsKey(entry.key)) {
        final current = _localWeights[entry.key]!;
        _localWeights[entry.key] = current + (entry.value - current) * 0.05;
      }
    }

    AppLogger.info(
        'Federated Learning: Local weights refined via peer ${packet.senderName}');
  }

  void _init() {
    _meshSubscription = _meshService.meshStream.listen((packet) {
      if (packet.type == MeshPayloadType.federatedDelta) {
        _handleIncomingDelta(packet);
      }
    });

    // Periodically broadcast local "Learning Trends" to neighbors
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_meshService.isMeshActive) {
        _broadcastLocalDelta();
      }
    });
  }
}
