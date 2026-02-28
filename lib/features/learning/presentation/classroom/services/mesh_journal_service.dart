import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';

/// Provider for the [MeshJournalService].
final meshJournalServiceProvider =
    StateNotifierProvider<MeshJournalService, JournalState>((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return MeshJournalService(mesh);
});

/// Represents the state of a collaborative mesh journal.
class JournalState {
  /// The text content of the journal.
  final String content;

  /// Timestamp of the last successful synchronization.
  final DateTime lastUpdated;

  /// Identifier of the user who last modified the content.
  final String updatedBy;

  /// Creates a [JournalState] instance.
  JournalState({
    required this.content,
    required this.lastUpdated,
    required this.updatedBy,
  });

  /// Creates a copy of [JournalState] with optional field updates.
  JournalState copyWith({
    String? content,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return JournalState(
      content: content ?? this.content,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

/// Service for synchronizing a shared text journal across the mesh network.
class MeshJournalService extends StateNotifier<JournalState> {
  final BluetoothMeshService _meshService;
  StreamSubscription? _meshSubscription;

  /// Sets up a new [MeshJournalService] with the provided mesh service.
  MeshJournalService(this._meshService)
      : super(JournalState(
          content: "",
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
          updatedBy: "System",
        )) {
    _initListener();
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    super.dispose();
  }

  /// Updates the journal content and broadcasts the change to the mesh network.
  void updateNote(String newContent) {
    final now = DateTime.now();
    state = state.copyWith(
      content: newContent,
      lastUpdated: now,
      updatedBy: 'Me',
    );

    _meshService.broadcastPacket(MeshPayloadType.chatMessage, {
      'msg_type': 'journal_sync',
      'text': newContent,
      'sync_ts': now.toIso8601String(),
    });
  }

  void _handleSync(MeshPacket packet) {
    final remoteTs = DateTime.parse(packet.payload['sync_ts']);
    if (remoteTs.isAfter(state.lastUpdated)) {
      state = JournalState(
        content: packet.payload['text'],
        lastUpdated: remoteTs,
        updatedBy: packet.senderName,
      );
    }
  }

  void _initListener() {
    _meshSubscription = _meshService.meshStream.listen((packet) {
      if (packet.type == MeshPayloadType.chatMessage &&
          packet.payload['msg_type'] == 'journal_sync') {
        _handleSync(packet);
      }
    });
  }
}
