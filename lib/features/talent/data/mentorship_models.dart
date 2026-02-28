/// Represents a mentorship booking.
class MentorshipBooking {
  /// The unique identifier for the booking.
  final String id;

  /// The ID of the student/mentee.
  final String studentId;

  /// The ID of the mentor.
  final String mentorId;

  /// The ID of the specific talent post/package booked.
  final String? talentPostId;

  /// The current status of the booking (e.g., 'pending', 'active').
  final String status; // 'pending', 'active', 'completed', 'cancelled'

  /// The billing period agreed upon.
  final String billingPeriod;

  /// The price at the time of booking.
  final double priceAtBooking;

  /// The currency at the time of booking.
  final String currencyAtBooking;

  /// The start date of the mentorship.
  final DateTime startDate;

  /// The end date of the mentorship.
  final DateTime? endDate;

  /// The date and time when the booking was created.
  final DateTime createdAt;

  // Joins
  /// The name of the mentor (joined field).
  final String? mentorName;

  /// The name of the student (joined field).
  final String? studentName;

  /// The title of the package (joined field).
  final String? packageTitle;

  /// Creates a [MentorshipBooking] instance.
  MentorshipBooking({
    required this.id,
    required this.studentId,
    required this.mentorId,
    this.talentPostId,
    this.status = 'pending',
    required this.billingPeriod,
    required this.priceAtBooking,
    this.currencyAtBooking = 'USD',
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.mentorName,
    this.studentName,
    this.packageTitle,
  });

  /// Creates a [MentorshipBooking] from a JSON map.
  factory MentorshipBooking.fromJson(Map<String, dynamic> json) {
    return MentorshipBooking(
      id: json['id'],
      studentId: json['student_id'],
      mentorId: json['mentor_id'],
      talentPostId: json['talent_post_id'],
      status: json['status'] ?? 'pending',
      billingPeriod: json['billing_period'],
      priceAtBooking: (json['price_at_booking'] ?? 0.0).toDouble(),
      currencyAtBooking: json['currency_at_booking'] ?? 'USD',
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      mentorName: json['mentor']?['full_name'],
      studentName: json['student']?['full_name'],
      packageTitle: json['talents']?['title'],
    );
  }

  /// Converts the [MentorshipBooking] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'mentor_id': mentorId,
      'talent_post_id': talentPostId,
      'status': status,
      'billing_period': billingPeriod,
      'price_at_booking': priceAtBooking,
      'currency_at_booking': currencyAtBooking,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}

/// Represents a single mentorship session.
class MentorshipSession {
  /// The unique identifier for the session.
  final String id;

  /// The ID of the booking this session belongs to.
  final String bookingId;

  /// The scheduled date and time for the session.
  final DateTime scheduledAt;

  /// The duration of the session in minutes.
  final int durationMinutes;

  /// The meeting link (e.g., Zoom, Google Meet).
  final String? meetingLink;

  /// The status of the session (e.g., 'scheduled', 'completed').
  final String status; // 'scheduled', 'ongoing', 'completed', 'missed'

  /// Notes for the session.
  final String? notes;

  /// The date and time when the session was created.
  final DateTime createdAt;

  /// Creates a [MentorshipSession] instance.
  MentorshipSession({
    required this.id,
    required this.bookingId,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.meetingLink,
    this.status = 'scheduled',
    this.notes,
    required this.createdAt,
  });

  /// Creates a [MentorshipSession] from a JSON map.
  factory MentorshipSession.fromJson(Map<String, dynamic> json) {
    return MentorshipSession(
      id: json['id'],
      bookingId: json['booking_id'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      durationMinutes: json['duration_minutes'] ?? 60,
      meetingLink: json['meeting_link'],
      status: json['status'] ?? 'scheduled',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [MentorshipSession] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'meeting_link': meetingLink,
      'status': status,
      'notes': notes,
    };
  }
}
