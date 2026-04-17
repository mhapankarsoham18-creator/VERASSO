import 'dart:typed_data';

import '../models/mesh_packet.dart';

/// Mesh network security layer.
///
/// Provides replay-attack prevention, TTL enforcement, hop-count limiting,
/// packet-size validation, and per-peer rate limiting.
/// Derived from VERASSO_SECURITY_PLAN-1.md (Layer 3 — Mesh Network Security).
class MeshSecurity {
  // ---------------------------------------------------------------------------
  // 1. REPLAY ATTACK PREVENTION
  //    Store seen message IDs.  Cap at 10 000 entries to prevent memory growth.
  // ---------------------------------------------------------------------------
  static final Set<String> _seenIds = {};
  static const int _maxSeenIds = 10000;

  /// Returns `true` when [packetId] has already been processed.
  static bool isReplay(String packetId) => _seenIds.contains(packetId);

  /// Marks [packetId] as processed.  When the set exceeds [_maxSeenIds] entries
  /// the entire set is cleared to bound memory usage.
  static void markSeen(String packetId) {
    _seenIds.add(packetId);
    if (_seenIds.length > _maxSeenIds) {
      _seenIds.clear();
      // Re-add the current ID so it is not immediately re-processed.
      _seenIds.add(packetId);
    }
  }

  /// Clears the replay-prevention cache.  Useful for testing.
  static void clearSeenIds() => _seenIds.clear();

  // ---------------------------------------------------------------------------
  // 2. TTL ENFORCEMENT
  //    Refuse to relay packets whose `expiresAt` is in the past.
  // ---------------------------------------------------------------------------

  /// Returns `true` when [packet] has expired according to its `expiresAt`.
  static bool isExpired(MeshPacket packet) {
    return DateTime.now().isAfter(packet.expiresAt);
  }

  // ---------------------------------------------------------------------------
  // 3. HOP COUNT LIMIT
  //    Max 7 hops — prevents infinite relay loops.
  // ---------------------------------------------------------------------------
  static const int maxHops = 7;

  /// Returns `true` when [packet] has reached or exceeded the hop limit.
  static bool exceedsHopLimit(MeshPacket packet) {
    return packet.hopCount >= maxHops;
  }

  // ---------------------------------------------------------------------------
  // 4. PACKET SIZE LIMIT
  //    Prevent oversized packets that could cause denial-of-service on BLE.
  // ---------------------------------------------------------------------------
  static const int maxPacketSize = 512; // bytes

  /// Returns `true` when [data] exceeds the maximum allowed packet size.
  static bool isOversized(Uint8List data) => data.length > maxPacketSize;

  // ---------------------------------------------------------------------------
  // 5. RATE LIMITING PER PEER
  //    Max 30 packets per minute per peer.
  // ---------------------------------------------------------------------------
  static final Map<String, List<DateTime>> _peerSendRates = {};
  static const int _maxPacketsPerMinute = 30;

  /// Returns `true` when [peerId] has sent more than [_maxPacketsPerMinute]
  /// packets in the last 60 seconds.
  static bool isPeerSpamming(String peerId) {
    final now = DateTime.now();
    _peerSendRates[peerId] ??= [];
    // Evict entries older than 60 seconds.
    _peerSendRates[peerId]!.removeWhere(
      (t) => now.difference(t).inSeconds > 60,
    );
    _peerSendRates[peerId]!.add(now);
    return _peerSendRates[peerId]!.length > _maxPacketsPerMinute;
  }

  /// Clears rate-limiting state.  Useful for testing.
  static void clearRateLimits() => _peerSendRates.clear();

  // ---------------------------------------------------------------------------
  // 6. COMBINED VALIDATION GATE
  // ---------------------------------------------------------------------------

  /// Validates a packet against all security rules.
  ///
  /// Returns `true` when the packet passes **every** check.
  /// When a packet is valid the ID is automatically marked as seen.
  static bool isPacketValid(MeshPacket packet, Uint8List rawData) {
    if (isReplay(packet.id)) return false;
    if (isExpired(packet)) return false;
    if (exceedsHopLimit(packet)) return false;
    if (isOversized(rawData)) return false;
    if (isPeerSpamming(packet.senderId)) return false;

    // All checks passed — record in replay set.
    markSeen(packet.id);
    return true;
  }
}
