import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';

import '../../../../../core/services/bluetooth_mesh_service.dart';

/// Provider for the [DoubtSwarmService].
final doubtSwarmServiceProvider =
    StateNotifierProvider<DoubtSwarmService, List<DoubtRequest>>((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return DoubtSwarmService(mesh);
});

/// Represents a help request shared via the doubt swarm mesh.
class DoubtRequest {
  /// Unique identifier for the help request.
  final String id;

  /// Name of the student asking the question.
  final String senderName;

  /// The subject/topic of the question.
  final String subject;

  /// The actual question or problem description.
  final String question;

  /// Time when the request was broadcast.
  final DateTime timestamp;

  /// Creates a [DoubtRequest] instance.
  DoubtRequest({
    required this.id,
    required this.senderName,
    required this.subject,
    required this.question,
    required this.timestamp,
  });
}

/// Service managing the "Doubt Swarm" - a mesh-based Q&A system for students.
class DoubtSwarmService extends StateNotifier<List<DoubtRequest>> {
  final BluetoothMeshService _meshService;
  StreamSubscription? _meshSubscription;

  /// Sets up a new [DoubtSwarmService] with the provided mesh service.
  DoubtSwarmService(this._meshService) : super([]) {
    _initListener();
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    super.dispose();
  }

  /// Broadcasts a help request for a specific question and subject.
  Future<void> requestHelp(String question, String subject) async {
    await _meshService.broadcastPacket(
      MeshPayloadType.doubtPost,
      {'question': question},
      targetSubject: subject,
    );
  }

  void _handleDoubtForMe(MeshPacket packet) {
    final request = DoubtRequest(
      id: packet.id,
      senderName: packet.senderName,
      subject: packet.targetSubject!,
      question: packet.payload['question'],
      timestamp: DateTime.parse(packet.timestamp),
    );

    // Add to list if not already there
    if (!state.any((r) => r.id == request.id)) {
      state = [...state, request];
    }
  }

  void _initListener() {
    _meshSubscription = _meshService.meshStream.listen((packet) {
      if (packet.type == MeshPayloadType.doubtPost &&
          packet.targetSubject != null) {
        // Check if I am an expert in this subject
        if (_meshService.expertise.contains(packet.targetSubject)) {
          _handleDoubtForMe(packet);
        }
      }
    });
  }
}
