import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/mesh_sync_manager.dart';

@GenerateMocks([BluetoothMeshService, MeshPacket])
import 'mesh_sync_stress_test.mocks.dart';

void main() {
  late MockBluetoothMeshService mockMeshService;
  late MeshSyncManager meshSyncManager;
  late StreamController<MeshPacket> meshStreamController;

  setUp(() {
    mockMeshService = MockBluetoothMeshService();
    meshStreamController = StreamController<MeshPacket>.broadcast();

    when(mockMeshService.meshStream)
        .thenAnswer((_) => meshStreamController.stream);
    when(mockMeshService.isMeshActive).thenReturn(true);

    meshSyncManager = MeshSyncManager(mockMeshService);
  });

  tearDown(() {
    meshSyncManager.dispose();
    meshStreamController.close();
  });

  group('MeshSyncManager Stress & Reliability Tests', () {
    test('Collision Detection: Prevents immediate duplicate requests',
        () async {
      final summaryPacket = MeshPacket(
        id: 'summary-1',
        senderId: 'peer-1',
        senderName: 'Peer 1',
        type: MeshPayloadType.meshSummary,
        payload: {
          'packetIds': ['missing-packet-123']
        },
        timestamp: DateTime.now().toIso8601String(),
      );

      // First summary received -> should trigger a request
      meshStreamController.add(summaryPacket);
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockMeshService.broadcastPacket(
        MeshPayloadType.packetRequest,
        any,
      )).called(1);

      // Second summary from different peer for same packet -> should be ignored (backoff)
      final summaryPacket2 = MeshPacket(
        id: 'summary-2',
        senderId: 'peer-2',
        senderName: 'Peer 2',
        type: MeshPayloadType.meshSummary,
        payload: {
          'packetIds': ['missing-packet-123']
        },
        timestamp: DateTime.now().toIso8601String(),
      );

      meshStreamController.add(summaryPacket2);
      await Future.delayed(const Duration(milliseconds: 100));

      // Clear the meshStream interaction which happens during initialization
      verify(mockMeshService.meshStream);

      // Still only 1 broadcastPacket call total because of backoff
      verifyNoMoreInteractions(mockMeshService);
    });

    test(
        'Expertise-Aware Prioritization: High trust peers get faster responses',
        () async {
      final requestHighTrust = MeshPacket(
        id: 'req-high',
        senderId: 'trust-peer',
        senderName: 'Trusted Peer',
        type: MeshPayloadType.packetRequest,
        payload: {
          'requestedIds': ['stored-packet-1'],
          'senderTrust': 95
        },
        timestamp: DateTime.now().toIso8601String(),
      );

      final requestLowTrust = MeshPacket(
        id: 'req-low',
        senderId: 'newbie-peer',
        senderName: 'Newbie Peer',
        type: MeshPayloadType.packetRequest,
        payload: {
          'requestedIds': ['stored-packet-2'],
          'senderTrust': 20
        },
        timestamp: DateTime.now().toIso8601String(),
      );

      // Pre-seed history
      final storedPacket1 = MeshPacket(
        id: 'stored-packet-1',
        senderId: 'me',
        senderName: 'Me',
        type: MeshPayloadType.chatMessage,
        payload: {'text': 'Hello High'},
        timestamp: DateTime.now().toIso8601String(),
      );
      final storedPacket2 = MeshPacket(
        id: 'stored-packet-2',
        senderId: 'me',
        senderName: 'Me',
        type: MeshPayloadType.chatMessage,
        payload: {'text': 'Hello Low'},
        timestamp: DateTime.now().toIso8601String(),
      );

      meshStreamController.add(storedPacket1);
      meshStreamController.add(storedPacket2);
      await Future.delayed(const Duration(milliseconds: 100));

      // Send both requests
      meshStreamController.add(requestHighTrust);
      meshStreamController.add(requestLowTrust);

      // High trust (95) has 0ms delay, Low trust (20) has 500ms delay.
      // After 250ms, only High trust should be fulfilled.
      await Future.delayed(const Duration(milliseconds: 250));

      verify(mockMeshService.broadcastPacket(
        MeshPayloadType.chatMessage,
        argThat(containsValue('Hello High')),
      )).called(1);

      verifyNever(mockMeshService.broadcastPacket(
        MeshPayloadType.chatMessage,
        argThat(containsValue('Hello Low')),
      ));

      // After 850ms total, Low trust should also be fulfilled (Delay is ~800ms)
      await Future.delayed(const Duration(milliseconds: 600));
      verify(mockMeshService.broadcastPacket(
        MeshPayloadType.chatMessage,
        argThat(containsValue('Hello Low')),
      )).called(1);
    });
  });
}
