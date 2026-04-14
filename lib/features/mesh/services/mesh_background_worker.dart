import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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

  // Define Battery Guard (mocked 20% limit for MVP)
  bool isBatteryCritical = false;

  // Background loop
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    // 1. Check Battery Guard
    // if (await getBatteryLevel() <= 20) { isBatteryCritical = true; }
    
    // ignore: dead_code
    if (isBatteryCritical) {
      debugPrint('[ENERGY MANAGER] Battery <= 20%. Mesh Relay sleeping.');
      await bleSignaling.stopAdvertising();
      // Only SOS packets theoretically bypass this, but we sleep normal relay.
      return;
    }

    // 2. Fetch next packet to advertise
    final currentPacket = meshStore.getNextPacketForBroadcast('BROADCAST');
    
    if (currentPacket != null) {
       // Convert string payload to byte chunks
       final bytes = currentPacket.payload.codeUnits;
       // Take first 24 bytes for PoC
       final chunk = bytes.length > 24 ? bytes.sublist(0, 24) : bytes;
       
       await bleSignaling.startAdvertising(chunk);
    } else {
       await bleSignaling.stopAdvertising();
    }
  });

  // Keep scanning passively 24/7
  await bleSignaling.startScanning((payload) {
    debugPrint('Background scan caught packet: $payload');
    // meshStore.insertPacket(...)
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
