import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/exceptions/user_friendly_error_handler.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/mentorship_models.dart';
import '../data/mentorship_repository.dart';

/// Provider that fetches mentorship bookings where the current user is the mentor.
final menteeBookingsProvider = FutureProvider<List<MentorshipBooking>>((ref) {
  return ref.watch(mentorshipRepositoryProvider).getMyMenteeBookings();
});

/// Screen for mentors to manage their incoming and active mentorship requests.
class MentorshipManagementScreen extends ConsumerWidget {
  /// Creates a [MentorshipManagementScreen].
  const MentorshipManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(menteeBookingsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Mentorship Management'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return const Center(
                  child: Text('No mentees yet. Promote your profile!'));
            }

            final pending =
                bookings.where((b) => b.status == 'pending').toList();
            final active = bookings.where((b) => b.status == 'active').toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
              children: [
                if (pending.isNotEmpty) ...[
                  const Text('Pending Requests',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...pending.map((b) => _buildRequestCard(context, ref, b)),
                  const SizedBox(height: 32),
                ],
                const Text('Active Mentees',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...active.map((b) => _buildMenteeCard(context, ref, b)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            message: UserFriendlyErrorHandler.getDisplayMessage(e),
            onRetry: () => ref.invalidate(menteeBookingsProvider),
          ),
        ),
      ),
    );
  }

  /// Shows a time picker dialog and returns the selected time.
  Future<TimeOfDay?> showTimeOfDay(BuildContext context) {
    return showTimePicker(context: context, initialTime: TimeOfDay.now());
  }

  Widget _buildMenteeCard(
      BuildContext context, WidgetRef ref, MentorshipBooking booking) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.studentName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(booking.packageTitle ?? 'Custom Mentorship',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.calendarPlus,
                    color: Colors.blueAccent),
                onPressed: () => _scheduleSession(context, ref, booking.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, WidgetRef ref, MentorshipBooking booking) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.studentName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Requested: ${booking.packageTitle}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              Text('\$${booking.priceAtBooking}',
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(ref, booking.id, 'cancelled'),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(ref, booking.id, 'active'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: const Text('Accept'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _scheduleSession(
      BuildContext context, WidgetRef ref, String bookingId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && context.mounted) {
      final TimeOfDay? time = await showTimeOfDay(context);
      if (time != null && context.mounted) {
        final scheduledAt = DateTime(
            picked.year, picked.month, picked.day, time.hour, time.minute);

        final session = MentorshipSession(
          id: '',
          bookingId: bookingId,
          scheduledAt: scheduledAt,
          createdAt: DateTime.now(),
          meetingLink:
              'https://meet.jit.si/verasso-${bookingId.substring(0, 8)}',
        );

        await ref.read(mentorshipRepositoryProvider).scheduleSession(session);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session Scheduled!')));
        }
      }
    }
  }

  void _updateStatus(WidgetRef ref, String id, String status) async {
    await ref
        .read(mentorshipRepositoryProvider)
        .updateBookingStatus(id, status);
    ref.invalidate(menteeBookingsProvider);
  }
}
