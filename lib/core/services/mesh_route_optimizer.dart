import 'dart:math';

import 'package:verasso/core/monitoring/app_logger.dart';

/// Optimizer that uses reinforcement learning to select the most reliable mesh peers.
class MeshRouteOptimizer {
  final Map<String, NodeStats> _nodeRegistry = {};
  final Random _random = Random();

  // RL Hyperparameters
  final double _epsilon = 0.2; // Exploration rate (20%)

  /// Returns a map of node IDs to their current trust/performance scores.
  Map<String, double> getTrustMap() {
    return _nodeRegistry.map((key, value) => MapEntry(key, value.score));
  }

  /// Selects the best peer for relaying based on RL (Multi-Armed Bandit)
  String? selectOptimalPeer(List<String> availablePeers) {
    if (availablePeers.isEmpty) return null;

    // Epsilon-Greedy: Explore random peer or Exploit best peer
    if (_random.nextDouble() < _epsilon) {
      // Exploration: Pick a random peer to gather new data
      final randomPeer = availablePeers[_random.nextInt(availablePeers.length)];
      AppLogger.info('MeshRouteOptimizer: Exploring random peer $randomPeer');
      return randomPeer;
    }

    // Exploitation: Pick the peer with the highest score
    String? bestPeer;
    double highestScore = -1.0;

    for (var peerId in availablePeers) {
      final stats = _nodeRegistry[peerId];
      // If no stats yet, give it a baseline mid-point score to encourage initial sampling
      double currentScore = stats?.score ?? 0.5;

      if (currentScore > highestScore) {
        highestScore = currentScore;
        bestPeer = peerId;
      }
    }

    AppLogger.info(
        'MeshRouteOptimizer: Exploiting best peer $bestPeer (Score: ${highestScore.toStringAsFixed(2)})');
    return bestPeer;
  }

  /// Updates the performance statistics for a specific [nodeId].
  void updateNodeStats(String nodeId,
      {required bool success, double? latencyMs}) {
    final stats = _nodeRegistry.putIfAbsent(nodeId, () => NodeStats());

    if (success) {
      stats.successCount++;
      if (latencyMs != null) {
        // Moving average for latency
        stats.averageLatencyMs =
            (stats.averageLatencyMs * 0.9) + (latencyMs * 0.1);
      }
    } else {
      stats.failureCount++;
    }
    stats.lastSeen = DateTime.now();
  }
}

/// Tracks performance and reliability statistics for a mesh node.
class NodeStats {
  /// Total successful interactions.
  int successCount = 0;

  /// Total failed interactions.
  int failureCount = 0;

  /// Current moving average of latency in milliseconds.
  double averageLatencyMs = 0.0;

  /// The timestamp of the last interaction with this node.
  DateTime lastSeen = DateTime.now();

  /// Calculates the reliability ratio (0.0 to 1.0).
  double get reliability => (successCount + failureCount) == 0
      ? 0.5
      : successCount / (successCount + failureCount);

  /// Calculates the overall performance score (0.0 to 1.0).
  double get score {
    // Score combines reliability and latency (lower latency is better)
    // Normalized latency score: 1.0 (0ms) to 0.0 (1000ms+)
    double latencyScore = max(0, 1.0 - (averageLatencyMs / 1000.0));
    return (reliability * 0.7) + (latencyScore * 0.3);
  }
}
