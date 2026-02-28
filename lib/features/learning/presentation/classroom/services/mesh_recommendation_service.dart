import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';

import '../../../../../core/services/bluetooth_mesh_service.dart';

/// Provider for the [MeshRecommendationService].
final meshRecommendationServiceProvider =
    StateNotifierProvider<MeshRecommendationService, List<PeerKnowledge>>(
        (ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return MeshRecommendationService(mesh);
});

/// Service for discoverability and peer-to-peer learning recommendations via mesh.
class MeshRecommendationService extends StateNotifier<List<PeerKnowledge>> {
  final BluetoothMeshService _meshService;
  StreamSubscription? _meshSubscription;
  Timer? _syncTimer;

  /// Sets up a new [MeshRecommendationService] with the provided mesh service.
  MeshRecommendationService(this._meshService) : super([]) {
    _initListener();
    _startPeriodicSync();
  }

  /// Broadcasts the current user's profile and expertise to the mesh network.
  void broadcastMyMetadata() {
    // In a real app, this would be fetched from local storage/database
    final myTopics = ["Optics", "Thermodynamics", "Linear Algebra"];

    _meshService.broadcastPacket(MeshPayloadType.profileSync, {
      'topics': myTopics,
    });
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Retrieves peer-to-peer knowledge recommendations based on an interest.
  List<String> getRecommendations(String currentInterest) {
    // Simple logic: Find peers who have topics matching the current interest
    // but possibly more advanced or related.
    final recs = <String>[];
    for (var peer in state) {
      for (var topic in peer.availableTopics) {
        if (topic.contains(currentInterest) ||
            currentInterest.contains(topic)) {
          recs.add("${peer.peerName} suggests: $topic");
        }
      }
    }
    return recs;
  }

  void _handleProfileSync(MeshPacket packet) {
    if (packet.payload['topics'] == null) return;

    final topics = List<String>.from(packet.payload['topics']);
    final knowledge = PeerKnowledge(
      peerId: packet.senderId,
      peerName: packet.senderName,
      availableTopics: topics,
      lastUpdated: DateTime.now(),
    );

    // Update or add
    final existingIndex = state.indexWhere((k) => k.peerId == knowledge.peerId);
    if (existingIndex != -1) {
      final newState = List<PeerKnowledge>.from(state);
      newState[existingIndex] = knowledge;
      state = newState;
    } else {
      state = [...state, knowledge];
    }
  }

  void _initListener() {
    _meshSubscription = _meshService.meshStream.listen((packet) {
      if (packet.type == MeshPayloadType.profileSync) {
        _handleProfileSync(packet);
      }
    });
  }

  void _startPeriodicSync() {
    // Broadcast my own "available knowledge" every 30 seconds
    _syncTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => broadcastMyMetadata());
  }
}

/// Represents the subjects and topics known by a nearby peer.
class PeerKnowledge {
  /// Unique identifier of the peer device.
  final String peerId;

  /// Display name of the peer student.
  final String peerName;

  /// List of educational topics the peer identifies as being proficient in.
  final List<String> availableTopics;

  /// Timestamp of the last received profile update.
  final DateTime lastUpdated;

  /// Creates a [PeerKnowledge] instance.
  PeerKnowledge({
    required this.peerId,
    required this.peerName,
    required this.availableTopics,
    required this.lastUpdated,
  });
}
