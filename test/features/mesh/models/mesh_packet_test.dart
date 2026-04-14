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
  });
}
