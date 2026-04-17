import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/mesh/models/mesh_packet.dart';
import 'package:verasso/features/mesh/services/mesh_security.dart';

void main() {
  setUp(() {
    // Reset static state between tests
    MeshSecurity.clearSeenIds();
    MeshSecurity.clearRateLimits();
  });

  MeshPacket makePacket({
    String id = 'test-id',
    String senderId = 'sender-1',
    String targetId = 'BROADCAST',
    PayloadType type = PayloadType.text,
    String payload = 'hello',
    int hopCount = 0,
    DateTime? expiresAt,
  }) {
    return MeshPacket(
      id: id,
      senderId: senderId,
      targetId: targetId,
      type: type,
      payload: payload,
      hopCount: hopCount,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 24)),
    );
  }

  group('MeshSecurity — Replay Prevention', () {
    test('isReplay returns false for unseen packet ID', () {
      expect(MeshSecurity.isReplay('never-seen'), false);
    });

    test('isReplay returns true after markSeen', () {
      MeshSecurity.markSeen('pkt-001');
      expect(MeshSecurity.isReplay('pkt-001'), true);
    });

    test('seen-ID set clears at 10k cap but retains the triggering ID', () {
      // Fill up to the cap
      for (int i = 0; i < 10001; i++) {
        MeshSecurity.markSeen('id-$i');
      }
      // The set was cleared at overflow — only the last id should survive
      expect(MeshSecurity.isReplay('id-10000'), true);
      // Earlier IDs were cleared
      expect(MeshSecurity.isReplay('id-0'), false);
    });
  });

  group('MeshSecurity — TTL Enforcement', () {
    test('isExpired returns false for future expiresAt', () {
      final packet = makePacket(
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(MeshSecurity.isExpired(packet), false);
    });

    test('isExpired returns true for past expiresAt', () {
      final packet = makePacket(
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(MeshSecurity.isExpired(packet), true);
    });
  });

  group('MeshSecurity — Hop Count Limit', () {
    test('exceedsHopLimit returns false when hopCount < maxHops', () {
      final packet = makePacket(hopCount: 0);
      expect(MeshSecurity.exceedsHopLimit(packet), false);
    });

    test('exceedsHopLimit returns false at hopCount = maxHops - 1', () {
      final packet = makePacket(hopCount: MeshSecurity.maxHops - 1);
      expect(MeshSecurity.exceedsHopLimit(packet), false);
    });

    test('exceedsHopLimit returns true at hopCount == maxHops', () {
      final packet = makePacket(hopCount: MeshSecurity.maxHops);
      expect(MeshSecurity.exceedsHopLimit(packet), true);
    });

    test('exceedsHopLimit returns true when hopCount > maxHops', () {
      final packet = makePacket(hopCount: MeshSecurity.maxHops + 5);
      expect(MeshSecurity.exceedsHopLimit(packet), true);
    });
  });

  group('MeshSecurity — Packet Size Limit', () {
    test('isOversized returns false for data within limit', () {
      final data = Uint8List(MeshSecurity.maxPacketSize);
      expect(MeshSecurity.isOversized(data), false);
    });

    test('isOversized returns true for data exceeding limit', () {
      final data = Uint8List(MeshSecurity.maxPacketSize + 1);
      expect(MeshSecurity.isOversized(data), true);
    });

    test('isOversized returns false for empty data', () {
      expect(MeshSecurity.isOversized(Uint8List(0)), false);
    });
  });

  group('MeshSecurity — Rate Limiting', () {
    test('isPeerSpamming returns false for first packet', () {
      expect(MeshSecurity.isPeerSpamming('peer-A'), false);
    });

    test('isPeerSpamming returns true after 30+ packets in 1 minute', () {
      // First 30 calls return false (within limit)
      for (int i = 0; i < 30; i++) {
        MeshSecurity.isPeerSpamming('peer-B');
      }
      // 31st call should return true
      expect(MeshSecurity.isPeerSpamming('peer-B'), true);
    });
  });

  group('MeshSecurity — Combined isPacketValid gate', () {
    test('valid packet passes all checks', () {
      final packet = makePacket(id: 'valid-1');
      final rawData = Uint8List.fromList(packet.toBytes());

      // Only works if rawData is within size — for tiny payloads it will be
      final isSmallEnough = rawData.length <= MeshSecurity.maxPacketSize;
      if (isSmallEnough) {
        expect(MeshSecurity.isPacketValid(packet, rawData), true);
      }
    });

    test('replayed packet is rejected', () {
      final packet = makePacket(id: 'replay-test');
      final rawData = Uint8List(100);

      MeshSecurity.markSeen('replay-test');
      expect(MeshSecurity.isPacketValid(packet, rawData), false);
    });

    test('expired packet is rejected', () {
      final packet = makePacket(
        id: 'expired-test',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final rawData = Uint8List(100);

      expect(MeshSecurity.isPacketValid(packet, rawData), false);
    });

    test('over-hop packet is rejected', () {
      final packet = makePacket(
        id: 'hop-test',
        hopCount: MeshSecurity.maxHops,
      );
      final rawData = Uint8List(100);

      expect(MeshSecurity.isPacketValid(packet, rawData), false);
    });

    test('oversized packet is rejected', () {
      final packet = makePacket(id: 'oversized-test');
      final rawData = Uint8List(MeshSecurity.maxPacketSize + 100);

      expect(MeshSecurity.isPacketValid(packet, rawData), false);
    });
  });
}
