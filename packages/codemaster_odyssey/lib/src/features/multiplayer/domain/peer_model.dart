/// Represents a peer user in the local MESH network.
class Peer {
  /// Unique identifier for the peer.
  final String id;

  /// Display name of the peer.
  final String name;

  /// Asset path for the peer's avatar.
  final String avatarAsset;

  /// Cursor position offset in a shared editor session.
  final int cursorOffset;

  /// The realm the peer is currently exploring.
  final String activeRealm;

  /// Creates a [Peer] instance.
  const Peer({
    required this.id,
    required this.name,
    required this.avatarAsset,
    this.cursorOffset = 0,
    required this.activeRealm,
  });

  /// Creates a copy of this [Peer] with the given fields replaced by new values.
  Peer copyWith({int? cursorOffset}) {
    return Peer(
      id: id,
      name: name,
      avatarAsset: avatarAsset,
      cursorOffset: cursorOffset ?? this.cursorOffset,
      activeRealm: activeRealm,
    );
  }
}
