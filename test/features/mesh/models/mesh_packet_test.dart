import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/mesh/models/mesh_packet.dart';

void main() {
  group('MeshPacket Tests', () {
    test('Initialization attributes are defined as expected', () {
      final packet = MeshPacket(
        senderId: 'Alice',
        targetId: 'Bob',
        type: PayloadType.text,
        payload: 'Hello Bob',
      );

      expect(packet.senderId, 'Alice');
      expect(packet.targetId, 'Bob');
      expect(packet.type, PayloadType.text);
      expect(packet.payload, 'Hello Bob');
      expect(packet.hopCount, 0);
      expect(packet.id.isNotEmpty, true);
      // Differs by standard 24 hours TTL
      expect(packet.expiresAt.difference(packet.createdAt).inHours, 24);
    });

    test('Payload size is calculated correctly', () {
      final packet = MeshPacket(
        senderId: 'A',
        targetId: 'B',
        type: PayloadType.text,
        payload: 'A' * 1024 * 1024, // 1MB block
      );

      // payloadSizeMB should be ~1.0
      expect(packet.payloadSizeMB, closeTo(1.0, 0.01));
    });

    test('Serialization and Deserialization retains equivalence', () {
      final original = MeshPacket(
        senderId: 'S1',
        targetId: 'T1',
        type: PayloadType.fileBeacon,
        payload: '{"ssid": "DIRECT-XX", "pass": "secret"}',
        hopCount: 2,
      );

      final map = original.toMap();
      
      expect(map['id'], original.id);
      expect(map['type'], 'fileBeacon');
      expect(map['hopCount'], 2);

      final recovered = MeshPacket.fromMap(map);

      expect(recovered.id, original.id);
      expect(recovered.senderId, original.senderId);
      expect(recovered.targetId, original.targetId);
      expect(recovered.type, original.type);
      expect(recovered.payload, original.payload);
      expect(recovered.hopCount, original.hopCount);
      expect(recovered.createdAt.isAtSameMomentAs(original.createdAt), true);
      expect(recovered.expiresAt.isAtSameMomentAs(original.expiresAt), true);
    });

    // --- Phase 1 additions: copyWith and byte serialization ---

    group('copyWith', () {
      test('copyWith produces a new instance with updated hopCount', () {
        final original = MeshPacket(
          senderId: 'Alice',
          targetId: 'Bob',
          type: PayloadType.text,
          payload: 'Hello',
          hopCount: 2,
        );

        final incremented = original.copyWith(hopCount: original.hopCount + 1);

        expect(incremented.hopCount, 3);
        // All other fields should remain the same
        expect(incremented.id, original.id);
        expect(incremented.senderId, original.senderId);
        expect(incremented.targetId, original.targetId);
        expect(incremented.type, original.type);
        expect(incremented.payload, original.payload);
        expect(
          incremented.createdAt.isAtSameMomentAs(original.createdAt),
          true,
        );
        expect(
          incremented.expiresAt.isAtSameMomentAs(original.expiresAt),
          true,
        );
      });

      test('copyWith with no arguments returns an equivalent packet', () {
        final original = MeshPacket(
          senderId: 'S',
          targetId: 'T',
          type: PayloadType.sos,
          payload: 'HELP',
          hopCount: 5,
        );

        final clone = original.copyWith();

        expect(clone.id, original.id);
        expect(clone.hopCount, original.hopCount);
        expect(clone.type, original.type);
      });

      test('copyWith can override multiple fields', () {
        final original = MeshPacket(
          senderId: 'A',
          targetId: 'B',
          type: PayloadType.text,
          payload: 'msg',
        );

        final modified = original.copyWith(
          senderId: 'X',
          payload: 'new msg',
          hopCount: 4,
        );

        expect(modified.senderId, 'X');
        expect(modified.payload, 'new msg');
        expect(modified.hopCount, 4);
        // Unchanged fields
        expect(modified.id, original.id);
        expect(modified.targetId, 'B');
      });
    });

    group('Byte serialization', () {
      test('toBytes and fromBytes round-trip preserves packet data', () {
        final original = MeshPacket(
          senderId: 'Sender1',
          targetId: 'Target1',
          type: PayloadType.text,
          payload: 'Round-trip test',
          hopCount: 3,
        );

        final bytes = original.toBytes();
        final recovered = MeshPacket.fromBytes(bytes);

        expect(recovered.id, original.id);
        expect(recovered.senderId, original.senderId);
        expect(recovered.targetId, original.targetId);
        expect(recovered.type, original.type);
        expect(recovered.payload, original.payload);
        expect(recovered.hopCount, original.hopCount);
      });
    });
  });
}
