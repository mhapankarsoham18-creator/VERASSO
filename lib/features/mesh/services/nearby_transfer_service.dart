import 'dart:io';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:verasso/core/utils/logger.dart';

class NearbyTransferService {
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  String currentEndpointId = '';

  Future<void> init() async {
    // In a real app we'd request NEARBY_WIFI_DEVICES permissions here
    appLogger.d('Nearby Transfer Service Initialized');
  }

  /// Called when the BLE Signaling layer detects a 'FILE_BEACON'
  /// We spin up an invisible hotspot waiting for the sender.
  Future<void> startAdvertisingHotspot(String userName) async {
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) async {
          // Auto accept for mesh protocol
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endid, payload) {
              if (payload.type == PayloadType.FILE) {
                // File received!
                appLogger.d('Received file payload from Mesh: ${payload.id}');
                // In production, save to getApplicationDocumentsDirectory()
              } else if (payload.type == PayloadType.BYTES) {
                 // Text/JSON fallback
              }
            },
            onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
               // Update UI with bytesTransferred / totalBytes
            },
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            currentEndpointId = id;
            appLogger.d('Mesh Wi-Fi Direct Connected!');
          } else {
            appLogger.d('Mesh Wi-Fi Connection failed');
          }
        },
        onDisconnected: (String id) {
          appLogger.d('Mesh Wi-Fi Direct Disconnected.');
          currentEndpointId = '';
        },
      );
      appLogger.d('Started Wi-Fi Direct Hotspot: $a');
    } catch (e) {
      appLogger.d('Error starting Wi-Fi direct: $e');
    }
  }

  /// Called to actively search for the advertised hotspot
  Future<void> startDiscoveringHotspot() async {
    try {
      bool a = await Nearby().startDiscovery(
        "verasso_mesh",
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) {
          // Found the target node, initiate connection
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (id, info) {
              Nearby().acceptConnection(id, onPayLoadRecieved: (id, p){}, onPayloadTransferUpdate: (id, p){});
            },
            onConnectionResult: (id, status) {
               if (status == Status.CONNECTED) {
                 currentEndpointId = id;
                 appLogger.d('Mesh Wi-Fi Direct Connected as Client!');
               }
            },
            onDisconnected: (id) {},
          );
        },
        onEndpointLost: (String? id) {},
      );
      appLogger.d('Started Wi-Fi Direct Discovery: $a');
    } catch (e) {
      appLogger.d('Error starting Wi-Fi discovery: $e');
    }
  }

  /// Send the actual >1MB file
  Future<void> sendLargeFile(File file) async {
    if (currentEndpointId.isEmpty) {
      appLogger.d('Cannot send file: No Wi-Fi Direct active connection');
      return;
    }
    
    int payloadId = await Nearby().sendFilePayload(currentEndpointId, file.path);
    appLogger.d('Queued file payload $payloadId over High-Bandwidth channel');
  }

  Future<void> shutdown() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
  }
}

