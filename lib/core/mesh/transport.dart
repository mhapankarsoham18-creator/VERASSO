import 'dart:typed_data';

/// Represents a change in the connection state of a mesh endpoint.
class MeshConnectionEvent {
  /// Unique ID representing the endpoint.
  final String endpointId;

  /// Human-readable name of the endpoint (optional).
  final String? endpointName;

  /// Connection state (found, lost, connected, etc.).
  final MeshConnectionState state;

  /// Authentication token if the connection is secured.
  final String? authenticationToken;

  /// Creates a [MeshConnectionEvent].
  MeshConnectionEvent({
    required this.endpointId,
    this.endpointName,
    required this.state,
    this.authenticationToken,
  });
}

/// Possible states for a mesh connection.
enum MeshConnectionState {
  /// Endpoint was discovered.
  found,

  /// Endpoint is no longer reachable.
  lost,

  /// Connection established.
  connected,

  /// Connection closed.
  disconnected,

  /// Connection attempt failed.
  failed,

  /// Connection attempt started.
  initiated,
}

/// Represents raw data received from a mesh endpoint.
class MeshDataPayload {
  /// ID of the endpoint that sent the data.
  final String endpointId;

  /// The raw byte data received.
  final Uint8List data;

  /// Creates a [MeshDataPayload].
  MeshDataPayload({
    required this.endpointId,
    required this.data,
  });
}

/// Common interface for different mesh transport mechanisms (Nearby, BLE, LAN).
abstract class MeshTransport {
  /// Stream of connection-related events (endpoints found, connected, disconnected).
  Stream<MeshConnectionEvent> get connectionEvents;

  /// Stream of raw data payloads received from the network.
  Stream<MeshDataPayload> get dataEvents;

  /// Accept an incoming connection request.
  Future<void> acceptConnection(String endpointId);

  /// Terminate a connection with an endpoint.
  Future<void> disconnect(String endpointId);

  /// Reject or ignore an incoming connection request.
  Future<void> rejectConnection(String endpointId);

  /// Send raw bytes to a specific endpoint.
  Future<void> sendData(String endpointId, Uint8List data);

  /// Start advertising this node to the network.
  Future<bool> startAdvertising(String name);

  /// Start discovering other nodes in the network.
  Future<bool> startDiscovery(String name);

  /// Stop advertising.
  Future<void> stopAdvertising();

  /// Stop all networking operations and disconnect all endpoints.
  Future<void> stopAll();

  /// Stop discovering.
  Future<void> stopDiscovery();
}
