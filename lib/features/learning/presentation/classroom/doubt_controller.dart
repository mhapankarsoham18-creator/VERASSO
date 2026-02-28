import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/learning/data/doubt_model.dart';
import 'package:verasso/features/learning/data/doubt_repository.dart';

/// Provider for the [DoubtController] instance.
final doubtControllerProvider =
    StateNotifierProvider<DoubtController, AsyncValue<void>>((ref) {
  return DoubtController(ref.watch(doubtRepositoryProvider), ref);
});

/// Provider for the [DoubtRepository] instance.
final doubtRepositoryProvider = Provider((ref) => DoubtRepository());

/// Future provider for fetching doubts, optionally filtered by subject.
final doubtsProvider =
    FutureProvider.family<List<Doubt>, String>((ref, subject) async {
  final repo = ref.watch(doubtRepositoryProvider);
  return repo.getDoubts(subject: subject);
});

/// Controller for managing doubts (questions) in the classroom.
class DoubtController extends StateNotifier<AsyncValue<void>> {
  final DoubtRepository _repo;
  final Ref _ref;

  /// Creates a [DoubtController] instance.
  DoubtController(this._repo, this._ref) : super(const AsyncData(null));

  /// Submits a new doubt, saves it to the repository, and broadcasts it over the mesh.
  Future<void> askDoubt({
    required String title,
    String? description,
    required String subject,
    File? image,
  }) async {
    state = const AsyncLoading();
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncError('User not logged in', StackTrace.empty);
      return;
    }

    state = await AsyncValue.guard(() async {
      await _repo.askDoubt(
          userId: user.id,
          title: title,
          description: description,
          subject: subject,
          image: image);

      // Broadcast over Mesh if active
      final mesh = _ref.read(bluetoothMeshServiceProvider);
      if (mesh.isMeshActive) {
        await mesh.broadcastPacket(MeshPayloadType.doubtPost, {
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'userId': user.id,
          'title': title,
          'description': description,
          'subject': subject,
        });
      }

      // Refresh the 'All' list and the specific subject list
      _ref.invalidate(doubtsProvider('All'));
      _ref.invalidate(doubtsProvider(subject));
    });
  }

  /// Marks a doubt as solved and invalidates relevant providers.
  Future<void> markSolved(String doubtId, String subject) async {
    // similar logic
    await _repo.markSolved(doubtId);
    _ref.invalidate(doubtsProvider(subject));
  }
}
