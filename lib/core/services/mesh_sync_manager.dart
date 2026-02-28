import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/mesh_route_optimizer.dart';

import '../mesh/models/mesh_packet.dart';
import 'bluetooth_mesh_service.dart';

/// Provider for the [MeshSyncManager] instance.
final meshSyncManagerProvider = Provider<MeshSyncManager>((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return MeshSyncManager(mesh);
});

/// Manager that handles the synchronization of data packets across the mesh network.
class MeshSyncManager {
  final BluetoothMeshService _meshService;
  final Map<String, MeshPacket> _packetHistory = {};
  final List<String> _recentIds = [];
  final MeshRouteOptimizer _optimizer = MeshRouteOptimizer();
  Timer? _summaryTimer;
  StreamSubscription? _meshSubscription;

  final Map<String, DateTime> _pendingRequests = {};

  /// Creates a [MeshSyncManager] and initializes network listeners.
  MeshSyncManager(this._meshService) {
    _init();
  }

  /// Disposes of the manager and cancels active timers/subscriptions.
  void dispose() {
    _summaryTimer?.cancel();
    _meshSubscription?.cancel();
  }

  void _broadcastSummary() {
    if (_recentIds.isEmpty) return; // Don't broadcast empty summaries

    AppLogger.info(
        'Broadcasting Mesh Summary: ${_recentIds.length} recent packets');
    _meshService.broadcastPacket(
      MeshPayloadType.meshSummary,
      {'packetIds': _recentIds},
    );
  }

  void _handlePacketRequest(MeshPacket requestPacket) {
    final requestedIds =
        List<String>.from(requestPacket.payload['requestedIds'] ?? []);

    for (var id in requestedIds) {
      if (_packetHistory.containsKey(id)) {
        // Expertise-aware prioritization: High trust peers get responses faster
        // Using RL scores if available, otherwise fallback to payload trust
        final nodeStats = _optimizer.getTrustMap()[requestPacket.senderName];
        final trustScore = (nodeStats ??
                (requestPacket.payload['senderTrust']?.toDouble() ?? 50.0)) /
            100.0;

        // Dynamic delay based on trust (reproducible from Mesh Networking Best Practices)
        // High trust (1.0) -> 0ms delay. Low trust (0.0) -> 1000ms delay.
        final delay = ((1.0 - trustScore) * 1000).toInt();

        final startTime = DateTime.now();
        Future.delayed(Duration(milliseconds: delay), () {
          // Re-verify we still have the packet after the delay
          if (!_packetHistory.containsKey(id)) return;

          AppLogger.info(
              'Mesh Sync: Fulfilling packet request for $id to ${requestPacket.senderName} (Delay: ${delay}ms)');
          _meshService.broadcastPacket(
            _packetHistory[id]!.type,
            _packetHistory[id]!.payload,
          );

          // Track "Success" in local optimizer for the sender
          _optimizer.updateNodeStats(requestPacket.senderName,
              success: true,
              latencyMs: DateTime.now()
                  .difference(startTime)
                  .inMilliseconds
                  .toDouble());
        });
      }
    }
  }

  void _handleSummary(MeshPacket summaryPacket) {
    final neighborIds =
        List<String>.from(summaryPacket.payload['packetIds'] ?? []);
    final List<String> missingIds = [];

    for (var id in neighborIds) {
      if (!_packetHistory.containsKey(id)) {
        // Collision Detection/Avoiding Duplicate Requests:
        // If we recently requested this packet, don't request it again immediately (Exponential Backoff principle)
        final lastRequested = _pendingRequests[id];
        if (lastRequested == null ||
            DateTime.now().difference(lastRequested).inSeconds > 10) {
          missingIds.add(id);
          _pendingRequests[id] = DateTime.now();
        }
      }
    }

    if (missingIds.isNotEmpty) {
      AppLogger.info(
          'Mesh Sync: Requesting ${missingIds.length} missing packets from ${summaryPacket.senderName}');
      _meshService.broadcastPacket(
        MeshPayloadType.packetRequest,
        {'requestedIds': missingIds},
      );
    }
  }

  void _init() {
    // Listen for incoming packets to store in history and respond to requests
    _meshSubscription = _meshService.meshStream.listen((packet) {
      try {
        _storeInHistory(packet);
        if (packet.type == MeshPayloadType.meshSummary) {
          _handleSummary(packet);
        } else if (packet.type == MeshPayloadType.packetRequest) {
          _handlePacketRequest(packet);
        }
      } catch (e, stack) {
        AppLogger.error('MeshSyncManager: Error processing packet', error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    });

    // Start periodic summary broadcast (every 60 seconds)
    _summaryTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_meshService.isMeshActive) {
        _broadcastSummary();
      }
    });
  }

  void _storeInHistory(MeshPacket packet) {
    // Don't store utility packets in history
    if (packet.type == MeshPayloadType.meshSummary ||
        packet.type == MeshPayloadType.packetRequest) {
      return;
    }

    if (!_packetHistory.containsKey(packet.id)) {
      _packetHistory[packet.id] = packet;
      _recentIds.add(packet.id);

      // Clean up fulfilled pending requests
      _pendingRequests.remove(packet.id);

      // Keep only last 100 packets
      if (_recentIds.length > 100) {
        final oldId = _recentIds.removeAt(0);
        _packetHistory.remove(oldId);
      }
    }
  }
}
