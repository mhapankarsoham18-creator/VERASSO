import 'dart:async';

import 'package:flutter/services.dart';
import 'package:verasso/core/mesh/transport.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Implementation of [MeshTransport] for Apple Multipeer Connectivity.
///
/// This implementation provides a bridge to native iOS code via [MethodChannel]
/// for high-performance peer-to-peer communication using the Multipeer Connectivity Framework.
class ApplePeerTransport implements MeshTransport {
  static const MethodChannel _channel =
      MethodChannel('dev.verasso.mesh/apple_peer');

  final _connectionEvents = StreamController<MeshConnectionEvent>.broadcast();
  final _dataEvents = StreamController<MeshDataPayload>.broadcast();

  /// Creates a new instance of [ApplePeerTransport] and sets up the native method call handler.
  ApplePeerTransport() {
    _channel.setMethodCallHandler(_handleNativeCallback);
  }

  @override
  Stream<MeshConnectionEvent> get connectionEvents => _connectionEvents.stream;

  @override
  Stream<MeshDataPayload> get dataEvents => _dataEvents.stream;

  @override
  Future<void> acceptConnection(String endpointId) async {
    await _channel.invokeMethod('acceptConnection', {'endpointId': endpointId});
  }

  @override
  Future<void> disconnect(String endpointId) async {
    await _channel.invokeMethod('disconnect', {'endpointId': endpointId});
  }

  @override
  Future<void> rejectConnection(String endpointId) async {
    await _channel.invokeMethod('rejectConnection', {'endpointId': endpointId});
  }

  @override
  Future<void> sendData(String endpointId, Uint8List data) async {
    await _channel.invokeMethod('sendData', {
      'endpointId': endpointId,
      'data': data,
    });
  }

  @override
  Future<bool> startAdvertising(String name) async {
    try {
      final bool? success =
          await _channel.invokeMethod('startAdvertising', {'name': name});
      return success ?? false;
    } catch (e) {
      AppLogger.error('ApplePeerTransport: Failed to start advertising',
          error: e);
      return false;
    }
  }

  @override
  Future<bool> startDiscovery(String name) async {
    try {
      final bool? success =
          await _channel.invokeMethod('startDiscovery', {'name': name});
      return success ?? false;
    } catch (e) {
      AppLogger.error('ApplePeerTransport: Failed to start discovery',
          error: e);
      return false;
    }
  }

  @override
  Future<void> stopAdvertising() async {
    await _channel.invokeMethod('stopAdvertising');
  }

  @override
  Future<void> stopAll() async {
    await _channel.invokeMethod('stopAll');
  }

  @override
  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopDiscovery');
  }

  Future<void> _handleNativeCallback(MethodCall call) async {
    try {
      final arguments = call.arguments as Map?;
      final endpointId = arguments?['endpointId'] as String?;

      if (endpointId == null) return;

      switch (call.method) {
        case 'onConnectionEvent':
          final stateInt = arguments?['state'] as int?;
          if (stateInt != null) {
            _connectionEvents.add(MeshConnectionEvent(
              endpointId: endpointId,
              state: MeshConnectionState.values[stateInt],
            ));
          }
        case 'onDataReceived':
          final data = arguments?['data'] as Uint8List?;
          if (data != null) {
            _dataEvents.add(MeshDataPayload(
              endpointId: endpointId,
              data: data,
            ));
          }
        default:
          AppLogger.error(
            'ApplePeerTransport: Unknown native callback: ${call.method}',
            error: 'Unknown method',
          );
      }
    } catch (e) {
      AppLogger.error('ApplePeerTransport: Failed to handle native callback',
          error: e);
    }
  }
}
