import 'dart:async';
import 'dart:ui';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/mesh_packet.dart';
import 'mesh_security.dart';
import 'mesh_store.dart';
import 'ble_signaling_service.dart';

@pragma("vm:entry-point")
void onBackgroundStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize Mesh Systems inside the isolate
  final meshStore = MeshStore();
  await meshStore.init();

  final bleSignaling = BleSignalingService();
  await bleSignaling.init();

  // Bring service to foreground with persistent notification
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Verasso Mesh",
      content: "Relaying packets for study group...",
    );
  }

  // Battery Guard — real device battery monitoring
  final battery = Battery();

  // Background loop
  Timer.periodic(Duration(seconds: 15), (timer) async {
    // 1. Check Battery Guard — real battery level via battery_plus
    final batteryLevel = await battery.batteryLevel;
    final isBatteryCritical = batteryLevel <= 20;

    if (isBatteryCritical) {
      debugPrint('[ENERGY MANAGER] Battery at $batteryLevel% (<= 20%). Mesh Relay sleeping.');
      await bleSignaling.stopAdvertising();
      // Only SOS packets theoretically bypass this, but we sleep normal relay.
      return;
    }

    // 2. Fetch next packet to advertise
    final currentPacket = meshStore.getNextPacketForBroadcast('BROADCAST');

    if (currentPacket != null) {
      // Validate the packet passes all security checks before rebroadcasting
      if (MeshSecurity.exceedsHopLimit(currentPacket)) {
        debugPrint('[MESH] Dropping packet ${currentPacket.id}: hop limit exceeded');
        return;
      }

      if (MeshSecurity.isExpired(currentPacket)) {
        debugPrint('[MESH] Dropping packet ${currentPacket.id}: expired');
        return;
      }

      // Increment hop count before broadcast (immutable via copyWith)
      final relayedPacket = currentPacket.copyWith(
        hopCount: currentPacket.hopCount + 1,
      );

      // Encode the full packet to size-limited bytes for BLE advertisement
      final packetBytes = relayedPacket.toBytes();

      // Enforce BLE advertisement size limit
      if (packetBytes.length > MeshSecurity.maxPacketSize) {
        debugPrint('[MESH] Packet ${relayedPacket.id} exceeds ${MeshSecurity.maxPacketSize} bytes, skipping BLE broadcast');
        return;
      }

      await bleSignaling.startAdvertising(packetBytes);
    } else {
      await bleSignaling.stopAdvertising();
    }
  });

  // Keep scanning passively 24/7
  await bleSignaling.startScanning((List<int> payload) {
    debugPrint('Background scan caught packet: $payload');

    // Parse received BLE advertisement bytes back into a MeshPacket
    try {
      final packet = MeshPacket.fromBytes(payload);
      final rawData = Uint8List.fromList(payload);

      // Validate with MeshSecurity before inserting
      if (MeshSecurity.isPacketValid(packet, rawData)) {
        meshStore.insertPacket(packet);
        debugPrint('[MESH] Accepted packet ${packet.id} from ${packet.senderId}');
      } else {
        debugPrint('[MESH] Rejected invalid packet from scan');
      }
    } catch (e) {
      debugPrint('[MESH] Error parsing scanned packet: $e');
    }
  });
}

class MeshBackgroundWorker {
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'verasso_mesh_channel',
        initialNotificationTitle: 'Verasso Mesh Network',
        initialNotificationContent: 'Offline relay is dormant',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onBackgroundStart,
        onBackground: onIosBackground,
      ),
    );
    await service.startService();
  }

  @pragma("vm:entry-point")
  static Future<bool> onIosBackground(ServiceInstance service) async {
    // iOS Background Fetch integration
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
}
