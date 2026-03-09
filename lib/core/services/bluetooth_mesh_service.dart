import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No-op provider for the Bluetooth Mesh Service (multiplayer removed).
final bluetoothMeshServiceProvider = Provider((ref) => BluetoothMeshService());

/// No-op implementation of the Bluetooth Mesh Service.
class BluetoothMeshService {
  bool get isMeshActive => false;
  Stream<dynamic> get meshStream => const Stream.empty();
  Stream<List<dynamic>> get connectedDevicesStream => const Stream.empty();

  Future<void> broadcastPacket(dynamic type, dynamic payload) async {}
  Future<void> startDiscovery() async {}
  void stopAll() {}
}
