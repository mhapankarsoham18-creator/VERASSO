import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';

/// Provider for the [RelayGameService].
final relayGameServiceProvider =
    StateNotifierProvider<RelayGameService, Map<String, RelayChain>>((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return RelayGameService(mesh);
});

/// Represents a chain of users who have "passed" a particular knowledge fact.
class RelayChain {
  /// Unique identifier for the relay instance.
  final String id;

  /// The educational fact being broadcasted.
  final String fact;

  /// Ordered list of user names who participated in the relay.
  final List<String> userChain;

  /// Ordered list of user IDs who participated in the relay.
  final List<String> idChain;

  /// Name of the student who initiated the relay.
  final String starterName;

  /// Timestamp of the last hop in the relay.
  final DateTime timestamp;

  /// Creates a [RelayChain] instance.
  RelayChain({
    required this.id,
    required this.fact,
    required this.userChain,
    required this.idChain,
    required this.starterName,
    required this.timestamp,
  });

  /// The current length of the relay chain.
  int get length => idChain.length;
}

/// Service managing the "Knowledge Relay" gamified learning experience over mesh.
class RelayGameService extends StateNotifier<Map<String, RelayChain>> {
  final BluetoothMeshService _meshService;
  StreamSubscription? _meshSubscription;

  /// Sets up a new [RelayGameService] with the provided mesh service.
  RelayGameService(this._meshService) : super({}) {
    _initListener();
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    super.dispose();
  }

  /// Passes a specific knowledge relay hop to nearby peers.
  Future<void> passRelay(String relayId) async {
    final relay = state[relayId];
    if (relay == null) return;

    final myId = _meshService.myId;
    if (myId == null) return;
    final myName = _meshService.myName ?? "Explorer";

    if (relay.idChain.contains(myId)) return; // Already passed

    final updatedUserChain = [...relay.userChain, myName];
    final updatedIdChain = [...relay.idChain, myId];

    final updatedRelay = RelayChain(
      id: relay.id,
      fact: relay.fact,
      userChain: updatedUserChain,
      idChain: updatedIdChain,
      starterName: relay.starterName,
      timestamp: DateTime.now(),
    );

    state = {...state, relayId: updatedRelay};

    await _meshService.broadcastPacket(MeshPayloadType.scienceData, {
      'game_type': 'knowledge_relay',
      'relay_id': relayId,
      'fact': relay.fact,
      'user_chain': updatedUserChain,
      'id_chain': updatedIdChain,
      'starter': relay.starterName,
    });
  }

  /// Initiates a new knowledge relay chain with the provided fact.
  Future<void> startNewRelay(String fact) async {
    final relayId = DateTime.now().millisecondsSinceEpoch.toString();
    final myId = _meshService.myId;
    if (myId == null) return;
    final myName = _meshService.myName ?? "Expert";

    final relay = RelayChain(
      id: relayId,
      fact: fact,
      userChain: [myName],
      idChain: [myId],
      starterName: myName,
      timestamp: DateTime.now(),
    );

    state = {...state, relayId: relay};

    await _meshService.broadcastPacket(MeshPayloadType.scienceData, {
      'game_type': 'knowledge_relay',
      'relay_id': relayId,
      'fact': fact,
      'user_chain': [myName],
      'id_chain': [myId],
      'starter': myName,
    });
  }

  void _handleRelayPacket(MeshPacket packet) {
    final payload = packet.payload;
    final relayId = payload['relay_id'];
    final fact = payload['fact'];
    final userChain = List<String>.from(payload['user_chain']);
    final idChain = List<String>.from(payload['id_chain']);
    final starter = payload['starter'];

    final relay = RelayChain(
      id: relayId,
      fact: fact,
      userChain: userChain,
      idChain: idChain,
      starterName: starter,
      timestamp: DateTime.now(),
    );

    // Only update if the incoming chain is longer than what we have
    final existing = state[relayId];
    if (existing == null || idChain.length > existing.idChain.length) {
      state = {...state, relayId: relay};
    }
  }

  void _initListener() {
    _meshSubscription = _meshService.meshStream.listen((packet) {
      if (packet.type == MeshPayloadType.scienceData &&
          packet.payload['game_type'] == 'knowledge_relay') {
        _handleRelayPacket(packet);
      }
    });
  }
}
