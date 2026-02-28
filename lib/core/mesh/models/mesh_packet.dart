/// Represents a single unit of data transmitted across the mesh network.
class MeshPacket {
  /// Unique identifier for the packet to prevent infinite relay loops.
  final String id;

  /// The unique ID of the original sender.
  final String senderId;

  /// The display name of the original sender.
  final String senderName;

  /// The type of data contained in this packet.
  final MeshPayloadType type;

  /// The actual data payload.
  final Map<String, dynamic> payload;

  /// Calculated trust score for the sender (0-100).
  final int trustScore;

  /// ISO-8601 timestamp when the packet was created.
  final String timestamp;

  /// List of node IDs that have already processed this packet.
  final List<String> seenBy;

  /// Optional topic or subject for targeted routing (Doubt Swarm).
  final String? targetSubject;

  /// Time-To-Live: Number of remaining hops allowed for this packet.
  final int ttl;

  /// Priority of the packet affecting relay ordering.
  final MeshPriority priority;

  /// Ed25519 cryptographic signature of the packet contents.
  final String? signature;

  /// Base64 encoded public key of the sender for signature verification.
  final String? publicKey;

  /// Optional Zero-Knowledge Proof for Sybil Resistance.
  final String? identityProof;

  /// Creates a [MeshPacket].
  MeshPacket({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.payload,
    this.ttl = 10, // Max 10 hops by default
    this.trustScore = 100, // Default full trust for prototype
    required this.timestamp,
    this.seenBy = const [],
    this.targetSubject,
    MeshPriority? priority,
    this.signature,
    this.publicKey,
    this.identityProof,
  }) : priority = priority ?? _determinePriority(type);

  /// Creates a [MeshPacket] from a JSON-compatible map.
  factory MeshPacket.fromMap(Map<String, dynamic> map) {
    return MeshPacket(
      id: map['id'],
      senderId: map['sid'],
      senderName: map['snm'],
      type: MeshPayloadType.values[map['typ']],
      payload: Map<String, dynamic>.from(map['pay']),
      ttl: map['ttl'],
      trustScore: map['trst'] ?? 100,
      timestamp: map['ts'],
      seenBy: List<String>.from(map['seen'] ?? []),
      targetSubject: map['sub'],
      priority: map['pri'] != null ? MeshPriority.values[map['pri']] : null,
      signature: map['sig'],
      publicKey: map['pk'],
      identityProof: map['zkp'],
    );
  }

  /// Creates a copy of this packet with updated [signature], [publicKey], [ttl], or [seenBy].
  MeshPacket copyWith({
    String? signature,
    String? publicKey,
    int? ttl,
    List<String>? seenBy,
    String? identityProof,
  }) {
    return MeshPacket(
      id: id,
      senderId: senderId,
      senderName: senderName,
      type: type,
      payload: payload,
      timestamp: timestamp,
      ttl: ttl ?? this.ttl,
      trustScore: trustScore,
      seenBy: seenBy ?? this.seenBy,
      targetSubject: targetSubject,
      priority: priority,
      signature: signature ?? this.signature,
      publicKey: publicKey ?? this.publicKey,
      identityProof: identityProof ?? this.identityProof,
    );
  }

  /// Converts this packet into a JSON-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sid': senderId,
      'snm': senderName,
      'typ': type.index,
      'pay': payload,
      'ttl': ttl,
      'trst': trustScore,
      'ts': timestamp,
      'seen': seenBy,
      'sub': targetSubject,
      'pri': priority.index,
      'sig': signature,
      'pk': publicKey,
      'zkp': identityProof,
    };
  }

  static MeshPriority _determinePriority(MeshPayloadType type) {
    switch (type) {
      case MeshPayloadType.handshake:
      case MeshPayloadType.ack:
      case MeshPayloadType.doubtRaise:
      case MeshPayloadType.pollVote:
        return MeshPriority.high;
      case MeshPayloadType.chatMessage:
      case MeshPayloadType.arAnchor:
      case MeshPayloadType.scienceData:
      case MeshPayloadType.doubtPost:
        return MeshPriority.medium;
      case MeshPayloadType.profileSync:
      case MeshPayloadType.feedPost:
      case MeshPayloadType.startSession:
      case MeshPayloadType.joinSession:
      case MeshPayloadType.pollPublish:
      case MeshPayloadType.sessionSummary:
      case MeshPayloadType.meshSummary:
      case MeshPayloadType.packetRequest:
      case MeshPayloadType.portfolioSync:
      case MeshPayloadType.federatedDelta:
        return MeshPriority.low;
    }
  }
}

/// Categorizes the purpose of a [MeshPacket].
enum MeshPayloadType {
  /// Initial greeting and identity verification.
  handshake,

  /// Direct user chat communication.
  chatMessage,

  /// Public feed updates.
  feedPost,

  /// Shared augmented reality coordinate data.
  arAnchor,

  /// Experimental or telemetry data.
  scienceData,

  /// Academic questions or community doubts.
  doubtPost,

  /// User profile and progress synchronization.
  profileSync,

  /// Delivery acknowledgment.
  ack,

  /// Starts a live classroom or study session.
  startSession,

  /// Request to join an active session.
  joinSession,

  /// Broadcast of a live poll or activity.
  pollPublish,

  /// Submission of a vote in a poll.
  pollVote,

  /// Immediate request for help during a session.
  doubtRaise,

  /// Brief recap of session activity.
  sessionSummary,

  /// Inventory of data available for synchronization.
  meshSummary,

  /// Request for missing data packets.
  packetRequest,

  /// Synchronization of user's financial or point portfolio.
  portfolioSync,

  /// Small model or curriculum updates for localized learning.
  federatedDelta,
}

/// Defines the importance of a [MeshPacket] for prioritizing its relay.
enum MeshPriority {
  /// Background synchronization tasks.
  low,

  /// Standard user interactions.
  medium,

  /// Critical control signals and real-time events.
  high,

  /// Emergency/System-Critical alerts requiring ZK-proof.
  critical,
}
