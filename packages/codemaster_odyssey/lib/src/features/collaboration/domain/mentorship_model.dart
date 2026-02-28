/// Represents a request for mentorship or help from another user.
class MentorshipRequest {
  /// Unique identifier for the request.
  final String id;

  /// ID of the apprentice (user) requesting help.
  final String apprenticeId;

  /// Display name of the apprentice.
  final String apprenticeName;

  /// The specific coding topic or challenge they need help with.
  final String topic;

  /// Current status of the mentorship request.
  final MentorshipStatus status;

  /// The time when the request was created.
  final DateTime timestamp;

  /// Creates a [MentorshipRequest] instance.
  const MentorshipRequest({
    required this.id,
    required this.apprenticeId,
    required this.apprenticeName,
    required this.topic,
    this.status = MentorshipStatus.pending,
    required this.timestamp,
  });
}

/// Status of a mentorship request.
enum MentorshipStatus {
  /// Request has been sent but not yet accepted or declined.
  pending,

  /// A mentor has accepted the request and is currently helping.
  active,

  /// The help session has finished.
  completed,

  /// The request was rejected by a mentor or system.
  declined,
}
