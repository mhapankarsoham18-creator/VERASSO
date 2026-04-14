import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:verasso/features/mesh/models/mesh_packet.dart';
import 'package:verasso/features/mesh/services/mesh_store.dart';

void main() {
  late MeshStore meshStore;

  setUp(() async {
    final tempPath = await Directory.systemTemp.createTemp();
    Hive.init(tempPath.path);
    await Hive.openBox<Map>(MeshStore.boxName);
    meshStore = MeshStore();
  });

  tearDown(() async {
    await Hive.box<Map>(MeshStore.boxName).clear();
    await Hive.close();
  });

  group('MeshStore QoS and Queue handling', () {
    test('Allows normal packet insertion', () async {
      final packet = MeshPacket(
        senderId: 'UserA',
        targetId: 'UserB',
        type: PayloadType.text,
        payload: 'small payload',
      );

      final accepted = await meshStore.insertPacket(packet);
      expect(accepted, true);

      final storedPacket = meshStore.getNextPacketForBroadcast('UserC');
      expect(storedPacket?.id, packet.id);
    });

    test('Rejects packet exceeding 5MB single limit', () async {
      final packet = MeshPacket(
        senderId: 'UserA',
        targetId: 'UserB',
        type: PayloadType.text,
        payload: 'A' * ((1024 * 1024 * 6).toInt()), // ~6MB String
      );

      final accepted = await meshStore.insertPacket(packet);
      expect(accepted, false, reason: 'Must reject packets > 5MB limit');
    });

    test('Rejects more than 10 packets per sender limit', () async {
      // Insert exactly 10 packets from 'Spammer'
      for (int i = 0; i < 10; i++) {
        final accepted = await meshStore.insertPacket(
          MeshPacket(
            senderId: 'Spammer',
            targetId: 'UserB',
            type: PayloadType.text,
            payload: 'Msg $i',
          ),
        );
        expect(accepted, true);
      }

      // 11th packet from same sender should be rejected
      final accepted11 = await meshStore.insertPacket(
        MeshPacket(
          senderId: 'Spammer',
          targetId: 'UserB',
          type: PayloadType.text,
          payload: 'Msg 11',
        ),
      );
      
      expect(accepted11, false, reason: 'Must restrict to 10 packets per sender');
    });

    test('SOS emergency overrides payload rules (or queues normally without constraints in this simplified test)', () async {
       // Insert 10 packets
       for (int i = 0; i < 10; i++) {
         await meshStore.insertPacket(
           MeshPacket(
             senderId: 'Spammer',
             targetId: 'UserB',
             type: PayloadType.text,
             payload: 'Msg $i',
           ),
         );
       }
       
       // SOS overrides sender limit
       final sosPacket = MeshPacket(
          senderId: 'Spammer',
          targetId: 'BROADCAST',
          type: PayloadType.sos,
          payload: 'HELP',
       );
       final sosAccepted = await meshStore.insertPacket(sosPacket);
       expect(sosAccepted, true);
    });
  });
}
