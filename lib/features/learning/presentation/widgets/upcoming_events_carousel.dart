import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../data/event_model.dart';
import '../../data/event_repository.dart';

/// Provider for the [EventRepository].
final eventRepositoryProvider = Provider((ref) => EventRepository());

/// FutureProvider that fetches and provides a list of upcoming events.
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).getUpcomingEvents();
});

/// A carousel widget that displays upcoming masterclasses and events.
class UpcomingEventsCarousel extends ConsumerWidget {
  /// Creates an [UpcomingEventsCarousel] instance.
  const UpcomingEventsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Upcoming Masterclasses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(context, events[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox(
          height: 160, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final dateStr = DateFormat('MMM d, h:mm a').format(event.startTime);

    return Semantics(
      button: true,
      label:
          'Event: ${event.title}. ${event.description}. Start time: $dateStr',
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.subject ?? 'GENERAL',
                      style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.calendar,
                      size: 14, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                event.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.arrowRight,
                      size: 14, color: Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
