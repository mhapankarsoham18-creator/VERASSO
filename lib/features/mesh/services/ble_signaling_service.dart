import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleSignalingService {
  // A custom UUID so Verasso devices only discover each other
  static const String verassoServiceUuid = '5A48F796-0A0C-4A2D-A1EB-FF1B11AC160B';

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  StreamSubscription? _scanSubscription;

  Future<void> init() async {
    // Wait for Bluetooth to be available
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint("Bluetooth not supported by this device");
      return;
    }
    
    // In a real app we'd request runtime permissions here if not granted yet.
  }

  /// Starts passively scanning for other Verasso devices in the background
  Future<void> startScanning(Function(List<int> payload) onPacketReceived) async {
    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          // Check if this advertisement contains our service UUID
          final serviceData = r.advertisementData.serviceData;
          final uuid = Guid(verassoServiceUuid);
          
          if (serviceData.containsKey(uuid)) {
            final payload = serviceData[uuid]!;
            onPacketReceived(payload);
          }
        }
      });

      // Start scanning specifically for our UUID to bypass iOS background filters
      await FlutterBluePlus.startScan(
        withServices: [Guid(verassoServiceUuid)], // Mandatory for iOS background
        continuousUpdates: true,
      );
      debugPrint('Started BLE Passive Scanning');
    } catch (e) {
      debugPrint('Error starting BLE scan: $e');
    }
  }

  void stopScanning() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  /// Broadcasts a tiny 24-byte payload using connectionless advertisement
  Future<void> startAdvertising(List<int> compressedPayload) async {
    if (compressedPayload.length > 24) {
      debugPrint('WARNING: Payload exceeds 24-bytes. May be truncated.');
    }

    final advertiseData = AdvertiseData(
      serviceUuid: verassoServiceUuid,
      manufacturerId: 0x0FFF, // Pseudo manufacturer ID
      manufacturerData: Uint8List.fromList(compressedPayload),
    );

    final advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
      connectable: false, // Connectionless broadcasting! Like AirTags.
    );

    try {
      await _blePeripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings,
      );
      debugPrint('Started BLE Advertising payload');
    } catch (e) {
      debugPrint('Error starting BLE advertising: $e');
    }
  }

  Future<void> stopAdvertising() async {
    await _blePeripheral.stop();
  }
}
