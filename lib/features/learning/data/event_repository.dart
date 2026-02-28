import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'event_model.dart';

/// Repository for managing educational events and webinars.
class EventRepository {
  final SupabaseClient _client;

  /// Creates an [EventRepository] instance.
  EventRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Creates a new educational event.
  Future<void> createEvent(Event event) async {
    await _client.from('events').insert(event.toJson());
  }

  /// Deletes a specific event by its ID.
  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  /// Retrieves a list of upcoming events.
  Future<List<Event>> getUpcomingEvents() async {
    final response = await _client
        .from('events')
        .select('*, profiles:organizer_id(full_name, avatar_url)')
        .gte('start_time', DateTime.now().toIso8601String())
        .order('start_time', ascending: true);

    return (response as List).map((json) => Event.fromJson(json)).toList();
  }
}
