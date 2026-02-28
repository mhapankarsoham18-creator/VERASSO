/// Represents an educational event or webinar.
class Event {
  /// Unique identifier of the event.
  final String id;

  /// The ID of the user who organized the event.
  final String organizerId;

  /// The title of the event.
  final String title;

  /// Optional detailed description of the event.
  final String? description;

  /// Optional subject area related to the event.
  final String? subject;

  /// The scheduled start time of the event.
  final DateTime startTime;

  /// The scheduled end time of the event.
  final DateTime? endTime;

  /// URL for joining the live event session.
  final String? linkUrl;

  /// Maximum number of students who can attend.
  final int? maxAttendees;

  /// The date and time when the event was created.
  final DateTime createdAt;

  /// Creates an [Event] instance.
  Event({
    required this.id,
    required this.organizerId,
    required this.title,
    this.description,
    this.subject,
    required this.startTime,
    this.endTime,
    this.linkUrl,
    this.maxAttendees,
    required this.createdAt,
  });

  /// Creates an [Event] from a JSON-compatible map.
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      organizerId: json['organizer_id'],
      title: json['title'],
      description: json['description'],
      subject: json['subject'],
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      linkUrl: json['link_url'],
      maxAttendees: json['max_attendees'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [Event] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'organizer_id': organizerId,
      'title': title,
      'description': description,
      'subject': subject,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'link_url': linkUrl,
      'max_attendees': maxAttendees,
    };
  }
}
