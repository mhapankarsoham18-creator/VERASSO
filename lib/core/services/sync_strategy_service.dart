import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bluetooth_mesh_service.dart';

/// No-op provider for Sync Strategy Service.
final syncStrategyServiceProvider = Provider((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return SyncStrategyService(mesh);
});

/// No-op implementation of Sync Strategy Service.
class SyncStrategyService {
  final BluetoothMeshService meshService;
  SyncStrategyService(this.meshService);

  Future<void> syncPendingActions() async {}
}
