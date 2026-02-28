import 'dart:async';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:verasso/core/mesh/transport.dart';

/// Implementation of [MeshTransport] using the Google Nearby Connections API.
class NearbyTransport implements MeshTransport {
  static const String _serviceId = "com.verasso.mesh";
  final Strategy _strategy = Strategy.P2P_CLUSTER;

  final _connectionController =
      StreamController<MeshConnectionEvent>.broadcast();
  final _dataController = StreamController<MeshDataPayload>.broadcast();

  @override
  Stream<MeshConnectionEvent> get connectionEvents =>
      _connectionController.stream;

  @override
  Stream<MeshDataPayload> get dataEvents => _dataController.stream;

  @override
  Future<void> acceptConnection(String endpointId) async {
    await Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (id, payload) {
        if (payload.type == PayloadType.BYTES) {
          _dataController.add(MeshDataPayload(
            endpointId: id,
            data: payload.bytes!,
          ));
        }
      },
    );
  }

  @override
  Future<void> disconnect(String endpointId) async {
    await Nearby().disconnectFromEndpoint(endpointId);
  }

  @override
  Future<void> rejectConnection(String endpointId) async {
    await Nearby().rejectConnection(endpointId);
  }

  @override
  Future<void> sendData(String endpointId, Uint8List data) async {
    await Nearby().sendBytesPayload(endpointId, data);
  }

  @override
  Future<bool> startAdvertising(String name) async {
    try {
      return await Nearby().startAdvertising(
        name,
        _strategy,
        onConnectionInitiated: (id, info) {
          _connectionController.add(MeshConnectionEvent(
            endpointId: id,
            endpointName: info.endpointName,
            state: MeshConnectionState.initiated,
            authenticationToken: info.authenticationToken,
          ));
        },
        onConnectionResult: (id, status) {
          _connectionController.add(MeshConnectionEvent(
            endpointId: id,
            state: status == Status.CONNECTED
                ? MeshConnectionState.connected
                : MeshConnectionState.failed,
          ));
        },
        onDisconnected: (id) {
          _connectionController.add(MeshConnectionEvent(
            endpointId: id,
            state: MeshConnectionState.disconnected,
          ));
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> startDiscovery(String name) async {
    try {
      return await Nearby().startDiscovery(
        name,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          _connectionController.add(MeshConnectionEvent(
            endpointId: id,
            endpointName: name,
            state: MeshConnectionState.found,
          ));
        },
        onEndpointLost: (id) {
          if (id != null) {
            _connectionController.add(MeshConnectionEvent(
              endpointId: id,
              state: MeshConnectionState.lost,
            ));
          }
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  @override
  Future<void> stopAll() async {
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
  }

  @override
  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
  }
}
