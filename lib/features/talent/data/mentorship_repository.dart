import 'package:flutter_riverpod/flutter_riverpod.dart'; // If using provider, but here we might need a workaround for repo-to-repo calls or just direct insert
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'mentorship_models.dart';

/// Provider for the [MentorshipRepository] instance.
final mentorshipRepositoryProvider = Provider<MentorshipRepository>((ref) {
  return MentorshipRepository();
});

/// Repository for managing mentorship bookings and sessions.
class MentorshipRepository {
  final SupabaseClient _client;

  /// Creates a [MentorshipRepository].
  MentorshipRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // --- Booking Management ---

  /// Completes a session and processes the payment.
  Future<void> completeSessionAndProcessPayment(
      String sessionId, double amount) async {
    // 1. Mark session as completed
    await updateSessionStatus(sessionId, 'Completed');

    // 2. Calculate Platform Fee (5%)
    final platformFee = amount * 0.05;

    // 3. Update Wallet (Actual Record)
    // We use a direct insert here since we don't have Ref access easily in this class structure without refactoring.
    // In a real app, use a Service or Cloud Function.

    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Credit
    await _client.from('transactions').insert({
      'user_id': userId,
      'type': 'Credit',
      'amount': amount,
      'category': 'Mentorship',
      'description': 'Session Earnings',
    });

    // Debit (Fee)
    await _client.from('transactions').insert({
      'user_id': userId,
      'type': 'Debit',
      'amount': platformFee,
      'category': 'Platform Fee',
      'description': '5% Service Fee',
    });
  }

  /// Creates a new mentorship booking.
  Future<void> createBooking(MentorshipBooking booking) async {
    await _client.from('mentorship_bookings').insert(booking.toJson());
  }

  /// Fetches bookings where the current user is the mentor.
  Future<List<MentorshipBooking>> getMyMenteeBookings() async {
    final mentorId = _client.auth.currentUser?.id;
    if (mentorId == null) return [];

    final response = await _client
        .from('mentorship_bookings')
        .select(
            '*, student:profiles!student_id(full_name, avatar_url), talents!talent_post_id(title)')
        .eq('mentor_id', mentorId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MentorshipBooking.fromJson(json))
        .toList();
  }

  /// Fetches bookings where the current user is the student.
  Future<List<MentorshipBooking>> getMyMentorBookings() async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) return [];

    final response = await _client
        .from('mentorship_bookings')
        .select(
            '*, mentor:profiles!mentor_id(full_name, avatar_url), talents!talent_post_id(title)')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MentorshipBooking.fromJson(json))
        .toList();
  }

  // --- Session Management ---

  /// Fetches upcoming sessions for a specific booking.
  Future<List<MentorshipSession>> getUpcomingSessions(String bookingId) async {
    final response = await _client
        .from('session_schedule')
        .select('*')
        .eq('booking_id', bookingId)
        .gte('scheduled_at', DateTime.now().toIso8601String())
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => MentorshipSession.fromJson(json))
        .toList();
  }

  /// Schedules a new mentorship session.
  Future<void> scheduleSession(MentorshipSession session) async {
    await _client.from('session_schedule').insert(session.toJson());
  }

  /// Updates the status of a booking.
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _client
        .from('mentorship_bookings')
        .update({'status': status}).eq('id', bookingId);
  }

  // --- Payment Processing (Phase 24) ---
  /// Updates the status of a session.
  Future<void> updateSessionStatus(String sessionId, String status) async {
    await _client
        .from('session_schedule')
        .update({'status': status}).eq('id', sessionId);
  }
}
