import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mesh_packet.dart';

class MeshStore {
  static String boxName = 'offline_mesh_queue';
  static const double maxQueueSizeMB = 50.0;
  static const int maxPacketsPerSender = 10;
  static const double maxSinglePacketSizeMB = 5.0;

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(boxName);
  }

  Box<Map> get _box => Hive.box<Map>(boxName);

  /// Returns true if the packet was accepted into the store, false if rejected by QoS
  Future<bool> insertPacket(MeshPacket packet) async {
    // 0. Deduplication check (Don't store if we already have it)
    if (_box.containsKey(packet.id)) {
      return true; // Already safely stored, so we return true as "handled"
    }

    // 1. QoS Check: Emergency SOS bypasses all limits
    if (packet.type == PayloadType.sos) {
      await _box.put(packet.id, packet.toMap());
      return true;
    }

    // 2. QoS Check: Max Single Packet Size
    if (packet.payloadSizeMB > maxSinglePacketSizeMB) {
      debugPrint('Mesh QoS Rejected: Packet exceeds 5MB limit');
      return false;
    }

    // 3. QoS Check: Max Packets Per Sender
    final existingPackets = _box.values.map((v) => MeshPacket.fromMap(Map<String, dynamic>.from(v)));
    final senderCount = existingPackets.where((p) => p.senderId == packet.senderId).length;
    
    if (senderCount >= maxPacketsPerSender) {
      debugPrint('Mesh QoS Rejected: Sender ${packet.senderId} reached 10 packet queue limit');
      return false;
    }

    // 4. QoS Check: Total Relay Storage Threshold (50MB Device Cap)
    double currentSizeMB = 0.0;
    final List<MeshPacket> allPackets = [];
    
    for (var value in _box.values) {
      final p = MeshPacket.fromMap(Map<String, dynamic>.from(value));
      allPackets.add(p);
      currentSizeMB += p.payloadSizeMB;
    }

    // If adding this packet puts us over 50MB, we must evict
    if (currentSizeMB + packet.payloadSizeMB > maxQueueSizeMB) {
      // Sort to find oldest non-emergency packets
      allPackets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      bool freedEnoughSpace = false;
      for (var p in allPackets) {
        if (p.type != PayloadType.sos) {
          await _box.delete(p.id);
          currentSizeMB -= p.payloadSizeMB;
          if (currentSizeMB + packet.payloadSizeMB <= maxQueueSizeMB) {
             freedEnoughSpace = true;
             break;
          }
        }
      }

      if (!freedEnoughSpace) {
         debugPrint('Mesh QoS Rejected: Queue is full and no non-emergency packets left to evict.');
         return false; // Box is full of SOS or we just couldn't clear enough
      }
    }

    // 5. Accepted! Insert packet
    await _box.put(packet.id, packet.toMap());
    return true;
  }

  /// Retrieves the next valid packet to broadcast/relay, handling expired packet cleanup
  MeshPacket? getNextPacketForBroadcast(String currentUserId) {
    if (_box.isEmpty) return null;

    final now = DateTime.now();
    MeshPacket? nextPacket;
    final keysToRemove = <dynamic>[];

    for (var key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null) {
        final p = MeshPacket.fromMap(Map<String, dynamic>.from(raw));
        
        // Garbage collection for expired packets
        if (now.isAfter(p.expiresAt)) {
          keysToRemove.add(key);
          continue;
        }

        // We don't broadcast packets meant for us (we just consume them)
        if (p.targetId == currentUserId) {
          continue; 
        }

        // Simple random/round-robin selection for next broadcast could be implemented here
        // For MVP, just returning the first valid one
        nextPacket ??= p;
      }
    }

    // Clean up expired ones
    for (var k in keysToRemove) {
      _box.delete(k);
    }

    return nextPacket;
  }
}
