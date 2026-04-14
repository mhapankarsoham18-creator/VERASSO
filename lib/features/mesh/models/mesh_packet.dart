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
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24)); // 24 hour TTL by default

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
}
