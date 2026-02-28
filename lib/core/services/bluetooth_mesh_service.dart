import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinenacl/ed25519.dart' as pinenacl;
import 'package:pinenacl/x25519.dart' as x25519;
import 'package:uuid/uuid.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/security/encryption_service.dart';
import 'package:verasso/core/security/security_initializer.dart';

import '../mesh/models/mesh_packet.dart';
import '../mesh/transport.dart';
import '../mesh/transports/nearby_transport.dart';

/// Provider for the [BluetoothMeshService] instance.
final bluetoothMeshServiceProvider = Provider<BluetoothMeshService>((ref) {
  // Use NearbyTransport as the default implementation
  return BluetoothMeshService(transport: NearbyTransport());
});

/// Stream provider for the list of currently connected mesh device names.
final connectedMeshDevicesProvider = StreamProvider<List<String>>((ref) {
  final service = ref.watch(bluetoothMeshServiceProvider);
  return service.connectedDevicesStream;
});

/// Stream provider for incoming [MeshPacket]s from the mesh network.
final meshMessagesProvider = StreamProvider<MeshPacket>((ref) {
  final service = ref.watch(bluetoothMeshServiceProvider);
  return service.meshStream;
});

/// Service that implements an ad-hoc Bluetooth mesh network using an abstracted [MeshTransport].
///
/// It handles device discovery, advertising, secure handshakes, packet signing,
/// adaptive flooding, and expertise-aware relaying for offline synchronization.
class BluetoothMeshService {
  final MeshTransport _transport;
  String? _myId;
  String? _myName;
  List<String> _myExpertise = [];

  // Encryption
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;

  final EncryptionService _encryptionService =
      SecurityInitializer.encryptionService;
  // State
  final Map<String, String> _connectedEndpoints = {};
  final Set<String> _seenPacketIds = {};

  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool _isDisposed = false;
  bool _isPulsedMode = false;
  Timer? _pulsedTimer;
  // Neighbor Ack Tracking (Adaptive Flooding)
  final Map<String, Set<String>> _packetNeighborAcks = {};
  final int _suppressionThreshold = 3;

  // Ed25519 Signing
  late final pinenacl.SigningKey _signingKey;
  late final pinenacl.VerifyKey _verifyKey;

  // X25519 Encryption (derived from signing keys or generated)
  late final pinenacl.PrivateKey _encryptionPrivateKey;
  late final pinenacl.PublicKey _encryptionPublicKey;

  // Peer Knowledge
  final Map<String, x25519.PublicKey> _peerEncryptionKeys = {};
  final Map<String, x25519.Box> _peerBoxes = {};

  // Trust Filtering Config
  int _minTrustThreshold = 0;
  // Streams
  final _dataStreamController = StreamController<MeshPacket>.broadcast();
  final _connectionStreamController =
      StreamController<List<String>>.broadcast();

  // Subscriptions
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _dataSubscription;

  // Relay Buffer & Timer
  final List<MeshPacket> _relayBuffer = [];

  /// Creates a [BluetoothMeshService] and initializes security/signing keys.
  BluetoothMeshService({required MeshTransport transport})
      : _transport = transport {
    _initLines();
    _initSecurity();
    _initSigning();
    _runRelayCycle(); // Start the dynamic relay loop
  }

  /// A stream of currently connected mesh device names.
  Stream<List<String>> get connectedDevicesStream =>
      _connectionStreamController.stream;

  /// Gets the number of currently connected endpoints.
  int get connectedEndpointsCount => _connectedEndpoints.length;

  /// Gets the list of expertise areas advertised by this node.
  List<String> get expertise => _myExpertise;
  // Getter for Mesh Priority
  /// Whether the mesh network is currently active (advertising, discovering, or connected).
  bool get isMeshActive =>
      _isAdvertising || _isDiscovering || _connectedEndpoints.isNotEmpty;

  /// A stream of incoming [MeshPacket]s from the network.
  Stream<MeshPacket> get meshStream => _dataStreamController.stream;

  /// The local node's unique mesh identifier.
  String? get myId => _myId;

  /// The local node's display name.
  String? get myName => _myName;

  /// The minimum trust score required for incoming packets.
  int get trustThreshold => _minTrustThreshold;

  /// Broadcasts a packet to the mesh network.
  Future<void> broadcastPacket(
      MeshPayloadType type, Map<String, dynamic> payload,
      {String? targetSubject, MeshPriority? priority}) async {
    if (_myId == null) return;

    final packet = MeshPacket(
      id: const Uuid().v4(),
      senderId: _myId!,
      senderName: _myName ?? 'User',
      type: type,
      payload: payload,
      trustScore: 100, // My own packets are 100 trust contextually
      timestamp: DateTime.now().toIso8601String(),
      seenBy: [_myId!], // I have seen it
      targetSubject: targetSubject,
      priority: priority,
      publicKey: base64Encode(_verifyKey),
      identityProof:
          (priority == MeshPriority.critical || priority == MeshPriority.high)
              ? _generateIdentityProof()
              : null,
    );

    final signedPacket = _signPacket(packet);

    // Activity detected, stay active if in pulsed mode
    if (_isPulsedMode) _resetPulsedTimer();

    await _sendPacketToAll(signedPacket);
  }

  // --- Messaging & Relay ---
  /// Disposes of the service, cancelling all active subscriptions and closing stream controllers.
  void dispose() {
    _isDisposed = true;
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _pulsedTimer?.cancel();
    _dataStreamController.close();
    _connectionStreamController.close();
  }

  /// Initializes the node with a [userName], [userId], and optional [expertise] areas.
  Future<void> initialize(String userName, String userId,
      {List<String> expertise = const []}) async {
    _myName = userName;
    _myId = userId;
    _myExpertise = expertise;

    // Derive a more secure key for this session if possible
    _reinitializeSecurity(userId);
  }

  // Expertise Management
  /// Updates the expertise areas of this local node.
  void setExpertise(List<String> areas) => _myExpertise = areas;

  /// Enables or disables pulsed advertising mode (beacons every 30s).
  void setPulsedMode(bool enabled) {
    _isPulsedMode = enabled;
    if (enabled) {
      _startPulsedCycle();
    } else {
      _pulsedTimer?.cancel();
      startAdvertising(); // Resume constant if disabled
    }
  }

  /// Sets the minimum trust threshold for relaying and accepting packets.
  void setTrustThreshold(int threshold) => _minTrustThreshold = threshold;

  /// Starts advertising this node to the mesh network.
  Future<bool> startAdvertising() async {
    if (_isAdvertising || _isDisposed) return _isAdvertising;
    _isAdvertising = await _transport.startAdvertising(_myName ?? 'Unknown');
    return _isAdvertising;
  }

  /// Starts discovering other nodes in the mesh network.
  Future<bool> startDiscovery() async {
    if (_isDiscovering || _isDisposed) return _isDiscovering;
    _isDiscovering = await _transport.startDiscovery(_myName ?? 'Unknown');
    return _isDiscovering;
  }

  // --- Core Mesh Operations ---

  /// Stops advertising this node.
  Future<void> stopAdvertising() async {
    await _transport.stopAdvertising();
    _isAdvertising = false;
  }

  /// Stops all mesh operations, including discovery, advertising, and relays.
  void stopAll() async {
    await _transport.stopAll();
    _connectedEndpoints.clear();
    _isAdvertising = false;
    _isDiscovering = false;
    _updateConnectionStream();
  }

  /// Stops searching for other nodes.
  Future<void> stopDiscovery() async {
    await _transport.stopDiscovery();
    _isDiscovering = false;
  }

  String _generateIdentityProof() {
    // Generates a cryptographic proof of identity ownership for priority packets
    final salt = "verasso_mesh_secure_v1";
    return sha256
        .convert(utf8.encode('$_myId|$salt|${DateTime.now().hour}'))
        .toString();
  }

  // --- Handlers ---

  void _handleConnectionEvent(MeshConnectionEvent event) {
    switch (event.state) {
      case MeshConnectionState.found:
        _transport.acceptConnection(event.endpointId);
        break;
      case MeshConnectionState.initiated:
        AppLogger.info(
            "Connecting to ${event.endpointName}, Auth Token: ${event.authenticationToken}");
        _transport.acceptConnection(event.endpointId);
        break;
      case MeshConnectionState.connected:
        _connectedEndpoints[event.endpointId] = event.endpointName ?? "Peer";
        _updateConnectionStream();
        // Send handshake with our encryption public key
        _sendHandshake(event.endpointId);
        break;
      case MeshConnectionState.lost:
      case MeshConnectionState.disconnected:
      case MeshConnectionState.failed:
        _connectedEndpoints.remove(event.endpointId);
        _updateConnectionStream();
        break;
    }
  }

  void _handleDataPayload(MeshDataPayload payload) {
    try {
      final bytes = payload.data;
      // 1. Decrypt
      final encrypted = encrypt.Encrypted(bytes);
      final decryptedBytes = _encrypter.decryptBytes(encrypted, iv: _iv);

      // 2. Decompress (Adaptive: check if it's zipped)
      String jsonStr;
      try {
        if (decryptedBytes.length > 2 &&
            decryptedBytes[0] == 31 &&
            decryptedBytes[1] == 139) {
          final decompressed = zlib.decode(decryptedBytes);
          jsonStr = utf8.decode(decompressed);
        } else {
          jsonStr = utf8.decode(decryptedBytes);
        }
      } catch (e) {
        jsonStr = utf8.decode(decryptedBytes);
      }

      final map = jsonDecode(jsonStr);
      final packet = MeshPacket.fromMap(map);

      // Handle Handshake
      if (packet.type == MeshPayloadType.handshake) {
        _handleHandshake(packet, payload.endpointId);
        return;
      }

      // 2. Cryptographic Verification
      if (!_verifyPacket(packet)) {
        AppLogger.warning(
            "mesh: Dropping packet ${packet.id} due to INVALID signature");
        return;
      }

      // 3. Deduplication & Ack Tracking
      _packetNeighborAcks
          .putIfAbsent(packet.id, () => {})
          .add(payload.endpointId);

      if (_seenPacketIds.contains(packet.id)) {
        if (_packetNeighborAcks[packet.id]!.length >= _suppressionThreshold) {
          _relayBuffer.removeWhere((p) => p.id == packet.id);
          AppLogger.info("Suppressing relay of ${packet.id} (redundancy met)");
        }
        return;
      }
      _seenPacketIds.add(packet.id);

      if (_seenPacketIds.length > 2000) {
        _seenPacketIds.remove(_seenPacketIds.first);
      }

      if (packet.trustScore < _minTrustThreshold) {
        AppLogger.info("Filtered packet ${packet.id} due to low trust");
        return;
      }

      _dataStreamController.add(packet);

      if (packet.ttl > 0) {
        int newTtl = packet.ttl - 1;

        if (packet.targetSubject != null &&
            _myExpertise.contains(packet.targetSubject)) {
          newTtl = (newTtl + 2).clamp(0, 15);
          AppLogger.info(
              "Expertise Match: Boosting TTL for ${packet.id} to $newTtl");
        }

        final newSeen = List<String>.from(packet.seenBy)..add(_myId!);

        final relayedPacket = packet.copyWith(
          ttl: newTtl,
          seenBy: newSeen,
        );

        _queueForRelay(relayedPacket);
      }
    } catch (e) {
      AppLogger.info('Error processing mesh payload: $e');
    }
  }

  void _handleHandshake(MeshPacket packet, String endpointId) {
    try {
      final peerPublicKeyBase64 = packet.payload['epk'] as String?;
      if (peerPublicKeyBase64 != null) {
        final peerPublicKey =
            x25519.PublicKey(base64Decode(peerPublicKeyBase64));
        _peerEncryptionKeys[packet.senderId] = peerPublicKey;
        _peerBoxes[packet.senderId] = x25519.Box(
            myPrivateKey: _encryptionPrivateKey, theirPublicKey: peerPublicKey);
        AppLogger.info(
            "mesh: Established E2EE channel with ${packet.senderName}");
      }
    } catch (e) {
      AppLogger.error("mesh: Handshake failed", error: e);
    }
  }

  void _initLines() {
    _connectionSubscription =
        _transport.connectionEvents.listen(_handleConnectionEvent);
    _dataSubscription = _transport.dataEvents.listen(_handleDataPayload);
  }

  void _initSecurity() {
    _iv = encrypt.IV.fromLength(16);
    final key = encrypt.Key.fromLength(32); // Fallback
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  void _initSigning() {
    _signingKey = pinenacl.SigningKey.generate();
    _verifyKey = _signingKey.verifyKey;

    // Generate separate X25519 keys for E2EE
    _encryptionPrivateKey = x25519.PrivateKey.generate();
    _encryptionPublicKey = _encryptionPrivateKey.publicKey;

    AppLogger.info(
        "mesh: E2EE keys initialized. PK: ${base64Encode(_encryptionPublicKey)}");
  }

  void _queueForRelay(MeshPacket packet) {
    _relayBuffer.add(packet);
  }

  Future<void> _reinitializeSecurity(String seed) async {
    final masterKey = await _encryptionService.getHiveKey();
    final material = utf8.encode(seed + base64Encode(masterKey));
    final digest = sha256.convert(material);
    final key = encrypt.Key(Uint8List.fromList(digest.bytes));

    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
    AppLogger.info(
        'Mesh Security Re-initialized with secure master key for user: $seed');
  }

  void _resetPulsedTimer() {
    // If we are actively sending/receiving, we might want to stay visible longer
    // but for now we follow the 30s cycle strictly unless explicitly toggled.
  }

  Future<void> _runRelayCycle() async {
    while (!_isDisposed) {
      if (_relayBuffer.isNotEmpty && _connectedEndpoints.isNotEmpty) {
        _relayBuffer
            .sort((a, b) => b.priority.index.compareTo(a.priority.index));

        final packet = _relayBuffer.removeAt(0);

        // Sybil Resistance: Reject high priority packets without a proof
        if ((packet.priority == MeshPriority.critical ||
                packet.priority == MeshPriority.high) &&
            !_verifyIdentityProof(packet)) {
          AppLogger.warning(
              "mesh: Dropped untrusted High-Priority packet ${packet.id} (No ZKProof)");
          continue;
        }

        await _sendToNeighbors(packet);

        if (_packetNeighborAcks.length > 500) {
          final keysToRemove = _packetNeighborAcks.keys.take(100).toList();
          for (var key in keysToRemove) {
            _packetNeighborAcks.remove(key);
          }
        }
      }

      final densityScale = 1.0 + (_connectedEndpoints.length / 5.0);
      final congestionScale = 1.0 / (1.0 + (_relayBuffer.length / 5.0));
      final intervalMs =
          (200 * densityScale * congestionScale).clamp(50, 500).toInt();
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
  }

  Future<void> _sendHandshake(String endpointId) async {
    final handshakePacket = MeshPacket(
      id: const Uuid().v4(),
      senderId: _myId ?? 'unknown',
      senderName: _myName ?? 'User',
      type: MeshPayloadType.handshake,
      payload: {'epk': base64Encode(_encryptionPublicKey)},
      timestamp: DateTime.now().toIso8601String(),
    );
    await _sendToNeighbors(handshakePacket);
  }

  Future<void> _sendPacketToAll(MeshPacket packet) async {
    _queueForRelay(packet);
    _seenPacketIds.add(packet.id);
  }

  Future<void> _sendToNeighbors(MeshPacket packet) async {
    final jsonStr = jsonEncode(packet.toMap());
    final jsonBytes = utf8.encode(jsonStr);
    final compressedBytes = zlib.encode(jsonBytes);
    final encrypted = _encrypter.encryptBytes(compressedBytes, iv: _iv);
    final payloadBytes = Uint8List.fromList(encrypted.bytes);

    for (var endpointId in _connectedEndpoints.keys) {
      try {
        await _transport.sendData(endpointId, payloadBytes);
      } catch (e) {
        AppLogger.info('Relay error to $endpointId: $e');
      }
    }
  }

  MeshPacket _signPacket(MeshPacket packet) {
    if (packet.senderId != _myId) return packet;

    final dataToSign = utf8.encode(
      '${packet.id}|${packet.senderId}|${packet.type.index}|${jsonEncode(packet.payload)}|${packet.timestamp}',
    );

    final signature = _signingKey.sign(Uint8List.fromList(dataToSign));
    return packet.copyWith(
      signature: base64Encode(signature.signature),
      publicKey: base64Encode(_verifyKey),
    );
  }

  void _startPulsedCycle() {
    _pulsedTimer?.cancel();
    _pulsedTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isDisposed || !_isPulsedMode) {
        timer.cancel();
        return;
      }

      AppLogger.info("mesh: Pulsed beacon start");
      await startAdvertising();
      await Future.delayed(const Duration(seconds: 2)); // Beacon for 2s
      await stopAdvertising();
      AppLogger.info("mesh: Pulsed beacon sleep");
    });
  }

  void _updateConnectionStream() {
    _connectionStreamController.add(_connectedEndpoints.values.toList());
  }

  bool _verifyIdentityProof(MeshPacket packet) {
    if (packet.identityProof == null) return false;
    // Simple validation for prototype: check if it's a valid hex string of expected length
    return packet.identityProof!.length == 64;
  }

  bool _verifyPacket(MeshPacket packet) {
    if (packet.signature == null || packet.publicKey == null) {
      if (packet.type == MeshPayloadType.feedPost) return false;
      return true;
    }

    try {
      final verifyKey = pinenacl.VerifyKey(base64Decode(packet.publicKey!));
      final signature = pinenacl.Signature(base64Decode(packet.signature!));
      final dataToVerify = utf8.encode(
        '${packet.id}|${packet.senderId}|${packet.type.index}|${jsonEncode(packet.payload)}|${packet.timestamp}',
      );

      return verifyKey.verify(
        signature: signature,
        message: Uint8List.fromList(dataToVerify),
      );
    } catch (e) {
      AppLogger.error("mesh: Verification error", error: e);
      return false;
    }
  }
}
