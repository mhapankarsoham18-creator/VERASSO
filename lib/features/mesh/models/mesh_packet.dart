import 'dart:convert';
import 'package:uuid/uuid.dart';

enum PayloadType { text, fileBeacon, sos }

class MeshPacket {
  final String id;
  final String senderId;
  final String targetId; // Supabase user ID, or 'BROADCAST'
  final PayloadType type;
  final String payload; // For text, it's the message. For fileBeacon, it's the Wi-Fi metadata. For SOS, it's GPS cord.
  final DateTime createdAt;
  final DateTime expiresAt;
  final int hopCount;

  MeshPacket({
    String? id,
    required this.senderId,
    required this.targetId,
    required this.type,
    required this.payload,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.hopCount = 0,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(Duration(hours: 24)); // 24 hour TTL by default

  // Get size of payload in MB to enforce the 5MB QoS limit
  double get payloadSizeMB {
    final bytes = utf8.encode(payload).length;
    return bytes / (1024 * 1024);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'targetId': targetId,
      'type': type.name,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'hopCount': hopCount,
    };
  }

  factory MeshPacket.fromMap(Map<String, dynamic> map) {
    return MeshPacket(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      targetId: map['targetId'] as String,
      type: PayloadType.values.firstWhere((e) => e.name == map['type']),
      payload: map['payload'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      hopCount: map['hopCount'] as int,
    );
  }

  /// Creates a copy of this packet with optional field overrides.
  /// Used to increment hop count before rebroadcast without mutating the original.
  MeshPacket copyWith({
    String? id,
    String? senderId,
    String? targetId,
    PayloadType? type,
    String? payload,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? hopCount,
  }) {
    return MeshPacket(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hopCount: hopCount ?? this.hopCount,
    );
  }

  /// Serializes the packet to a JSON-encoded UTF-8 byte list.
  /// Used for BLE advertisement payload encoding.
  List<int> toBytes() => utf8.encode(jsonEncode(toMap()));

  /// Deserializes a packet from a JSON-encoded UTF-8 byte list.
  factory MeshPacket.fromBytes(List<int> bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return MeshPacket.fromMap(json);
  }
}
