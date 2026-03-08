/// No-op MeshPacket and PayloadTypes.
class MeshPacket {
  final dynamic payload;
  final String senderName;
  final dynamic type;

  MeshPacket({required this.payload, required this.senderName, required this.type});
}

enum MeshPayloadType {
  doubtPost,
  feedPost,
  scienceData,
  joinSession,
  pollPublish,
  pollVote,
  doubtRaise,
  startSession,
  federatedDelta,
}
