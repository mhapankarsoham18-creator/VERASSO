import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:verasso/core/mesh/transport.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Implementation of [MeshTransport] using UDP/LAN for Desktop platforms.
class DesktopLanTransport implements MeshTransport {
  final _connectionEvents = StreamController<MeshConnectionEvent>.broadcast();
  final _dataEvents = StreamController<MeshDataPayload>.broadcast();
  RawDatagramSocket? _socket;
  final int _port = 5555;

  @override
  Stream<MeshConnectionEvent> get connectionEvents => _connectionEvents.stream;

  @override
  Stream<MeshDataPayload> get dataEvents => _dataEvents.stream;

  @override
  Future<void> acceptConnection(String endpointId) async {
    _connectionEvents.add(MeshConnectionEvent(
      endpointId: endpointId,
      state: MeshConnectionState.connected,
    ));
  }

  @override
  Future<void> disconnect(String endpointId) async {
    // No-op: handled by socket destruction on desktop LAN
  }

  @override
  Future<void> rejectConnection(String endpointId) async {
    // No-op: handled by ignoring incoming packets
  }

  @override
  Future<void> sendData(String endpointId, Uint8List data) async {
    if (_socket == null) return;
    try {
      // For demonstration, we'll multi-cast to the local network segment
      _socket?.send(data, InternetAddress('255.255.255.255'), _port);
    } catch (e) {
      AppLogger.error('DesktopLanTransport: Send failed', error: e);
    }
  }

  @override
  Future<bool> startAdvertising(String name) async {
    await _initSocket();
    AppLogger.info('DesktopLanTransport: Advertising on port $_port');
    return true;
  }

  @override
  Future<bool> startDiscovery(String name) async {
    await _initSocket();
    AppLogger.info('DesktopLanTransport: Discovering on port $_port');
    return true;
  }

  @override
  Future<void> stopAdvertising() async {
    // No-op: handled by stopAll()
  }

  @override
  Future<void> stopAll() async {
    _socket?.close();
    _socket = null;
  }

  @override
  Future<void> stopDiscovery() async {
    // No-op: handled by stopAll()
  }

  Future<void> _initSocket() async {
    if (_socket != null) return;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
    _socket?.broadcastEnabled = true;

    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket?.receive();
        if (datagram != null) {
          final peerId = datagram.address.address;
          _connectionEvents.add(MeshConnectionEvent(
            endpointId: peerId,
            endpointName: 'Desktop Peer ($peerId)',
            state: MeshConnectionState.connected,
          ));
          _dataEvents.add(MeshDataPayload(
            endpointId: peerId,
            data: datagram.data,
          ));
        }
      }
    });
  }
}
