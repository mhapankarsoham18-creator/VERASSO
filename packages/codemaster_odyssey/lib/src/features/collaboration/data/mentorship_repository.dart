import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mentorship_model.dart';

/// Provider for the [MentorshipRepository] instance.
final mentorshipProvider =
    NotifierProvider<MentorshipRepository, List<MentorshipRequest>>(
      MentorshipRepository.new,
    );

/// Repository responsible for managing mentorship requests and status.
class MentorshipRepository extends Notifier<List<MentorshipRequest>> {
  /// Accepts a mentorship request by its [id].
  void acceptRequest(String id) {
    state = [
      for (final req in state)
        if (req.id == id)
          MentorshipRequest(
            id: req.id,
            apprenticeId: req.apprenticeId,
            apprenticeName: req.apprenticeName,
            topic: req.topic,
            status: MentorshipStatus.active,
            timestamp: req.timestamp,
          )
        else
          req,
    ];
  }

  @override
  List<MentorshipRequest> build() {
    return [
      MentorshipRequest(
        id: 'req_1',
        apprenticeId: 'p1',
        apprenticeName: 'Zephyr',
        topic: 'Python Loops in Logic Labyrinth',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  /// Creates a new help request for the current user with a specific [topic].
  void requestHelp(String topic) {
    state = [
      ...state,
      MentorshipRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        apprenticeId: 'me',
        apprenticeName: 'You',
        topic: topic,
        timestamp: DateTime.now(),
      ),
    ];
  }
}
