import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/peer_model.dart';

/// Provider for the [MeshSyncRepository] instance.
final meshSyncProvider = NotifierProvider<MeshSyncRepository, List<Peer>>(
  MeshSyncRepository.new,
);

/// Repository responsible for discovering and syncing with peers in the MESH network.
class MeshSyncRepository extends Notifier<List<Peer>> {
  @override
  List<Peer> build() {
    // Initial peers discovered in mesh
    return [
      const Peer(
        id: 'p1',
        name: 'Apprentice Zephyr',
        avatarAsset: 'assets/avatars/zephyr.png',
        activeRealm: 'Python Plains',
      ),
      const Peer(
        id: 'p2',
        name: 'Apprentice Nova',
        avatarAsset: 'assets/avatars/nova.png',
        activeRealm: 'Python Plains',
      ),
    ];
  }

  /// Simulates a remote movement of a [peerId] by updating their [offset].
  void simulateRemoteMovement(String peerId, int offset) {
    state = [
      for (final p in state)
        if (p.id == peerId) p.copyWith(cursorOffset: offset) else p,
    ];
  }

  /// Starts the discovery of new peers in the mesh network.
  void startDiscovery() {
    // Simulate finding a new peer after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      state = [
        ...state,
        const Peer(
          id: 'p3',
          name: 'Sage Merlin',
          avatarAsset: 'assets/avatars/merlin.png',
          activeRealm: 'Logic Labyrinth',
        ),
      ];
    });
  }
}
