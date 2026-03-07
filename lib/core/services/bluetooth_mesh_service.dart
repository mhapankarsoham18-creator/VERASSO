import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/mesh/models/mesh_packet.dart';
import '../../core/monitoring/app_logger.dart';

class BluetoothMeshService {
  final _meshController = StreamController<MeshPacket>.broadcast();
  final _devicesController = StreamController<List<String>>.broadcast();

  final Map<String, String> _connectedDevices = {}; // endpointId -> deviceName

  bool _isAdvertising = false;
  bool _isDiscovering = false;

  String _myId = const Uuid().v4();
  String? _myName;

  bool get isMeshActive => _isAdvertising || _isDiscovering;
  Stream<MeshPacket> get meshStream => _meshController.stream;
  Stream<List<String>> get connectedDevicesStream => _devicesController.stream;
  int get connectedEndpointsCount => _connectedDevices.length;
  String get myId => _myId;
  String get myName => _myName ?? 'User_${_myId.substring(0, 4)}';
  List<String> get expertise => ['student'];
  int get trustThreshold => 50;

  Future<void> initialize([String? name, String? id]) async {
    _myName = name;
    if (id != null) _myId = id;

    // Request permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    AppLogger.info('BluetoothMeshService initialized as $myName ($myId)');
  }

  Future<void> stop() async {
    await stopAll();
  }

  Future<bool> startDiscovery() async {
    if (_isDiscovering) return true;
    try {
      _isDiscovering = await Nearby().startDiscovery(
        myName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          AppLogger.info('Mesh: Found endpoint $name ($id)');
          Nearby().requestConnection(
            myName,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (id) {
          AppLogger.info('Mesh: Lost endpoint $id');
        },
      );
      return _isDiscovering;
    } catch (e) {
      AppLogger.error('Mesh: Discovery failed', error: e);
      return false;
    }
  }

  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
    _isDiscovering = false;
  }

  Future<bool> startAdvertising() async {
    if (_isAdvertising) return true;
    try {
      _isAdvertising = await Nearby().startAdvertising(
        myName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      return _isAdvertising;
    } catch (e) {
      AppLogger.error('Mesh: Advertising failed', error: e);
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
    _isAdvertising = false;
  }

  Future<void> stopAll() async {
    await Nearby().stopAllEndpoints();
    await stopAdvertising();
    await stopDiscovery();
    _connectedDevices.clear();
    _devicesController.add([]);
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    AppLogger.info(
      'Mesh: Connection initiated with ${info.endpointName} ($id)',
    );
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (id, payload) {
        if (payload.type == PayloadType.BYTES) {
          final data = utf8.decode(payload.bytes!);
          try {
            final Map<String, dynamic> map = jsonDecode(data);
            final packet = MeshPacket.fromMap(map);
            _meshController.add(packet);
          } catch (e) {
            AppLogger.error('Mesh: Failed to decode packet', error: e);
          }
        }
      },
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      AppLogger.info('Mesh: Connected to $id');
      _connectedDevices[id] = id;
      _devicesController.add(_connectedDevices.values.toList());
    } else {
      AppLogger.warning('Mesh: Connection result to $id: $status');
    }
  }

  void _onDisconnected(String id) {
    AppLogger.info('Mesh: Disconnected from $id');
    _connectedDevices.remove(id);
    _devicesController.add(_connectedDevices.values.toList());
  }

  Future<void> broadcastPacket(
    dynamic type,
    dynamic payload, {
    dynamic targetSubject,
  }) async {
    final packet = MeshPacket(
      id: const Uuid().v4(),
      type: type is MeshPayloadType
          ? type
          : MeshPayloadType.values.firstWhere(
              (e) => e.toString() == type.toString(),
              orElse: () => MeshPayloadType.scienceData,
            ),
      senderId: myId,
      senderName: myName,
      payload: Map<String, dynamic>.from(payload),
      timestamp: DateTime.now().toIso8601String(),
    );

    final Map<String, dynamic> map = packet.toMap();
    final data = jsonEncode(map);
    final bytes = utf8.encode(data);

    for (var id in _connectedDevices.keys) {
      Nearby().sendBytesPayload(id, Uint8List.fromList(bytes));
    }
  }

  void setExpertise(dynamic level) {}
  void setTrustThreshold(dynamic threshold) {}
}

final bluetoothMeshServiceProvider = Provider<BluetoothMeshService>((ref) {
  return BluetoothMeshService();
});

final connectedMeshDevicesProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(bluetoothMeshServiceProvider).connectedDevicesStream;
});

final meshMessagesProvider = StreamProvider<MeshPacket>((ref) {
  return ref.watch(bluetoothMeshServiceProvider).meshStream;
});
