import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/services/mesh_route_optimizer.dart';

void main() {
  late MeshRouteOptimizer optimizer;

  setUp(() {
    optimizer = MeshRouteOptimizer();
  });

  group('MeshRouteOptimizer Tests', () {
    test('Should select a peer when peers are available', () {
      final peers = ['peer1', 'peer2', 'peer3'];
      final selected = optimizer.selectOptimalPeer(peers);
      expect(peers.contains(selected), isTrue);
    });

    test('Should return null when no peers are available', () {
      expect(optimizer.selectOptimalPeer([]), isNull);
    });

    test('Exploitation: Should favor high-success, low-latency nodes', () {
      // Setup node stats
      // Peer 1: High success, low latency (Best)
      for (int i = 0; i < 10; i++) {
        optimizer.updateNodeStats('best_peer', success: true, latencyMs: 10.0);
      }

      // Peer 2: High failure (Bad)
      for (int i = 0; i < 10; i++) {
        optimizer.updateNodeStats('bad_peer', success: false, latencyMs: 500.0);
      }

      // We run multiple trials to account for epsilon-exploration
      int bestPeerSelected = 0;
      final peers = ['best_peer', 'bad_peer'];

      for (int i = 0; i < 100; i++) {
        if (optimizer.selectOptimalPeer(peers) == 'best_peer') {
          bestPeerSelected++;
        }
      }

      // With epsilon = 0.2, we expect best_peer to be chosen ~80% + random share of 20%
      // So at least > 70 times
      expect(bestPeerSelected, greaterThan(70));
    });
  });
}
