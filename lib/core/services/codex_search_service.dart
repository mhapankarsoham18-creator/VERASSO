import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [CodexSearchService] instance.
final codexSearchServiceProvider = Provider((ref) => CodexSearchService());

/// Represents a searchable entry in the Verasso Codex.
class CodexEntry {
  /// The unique identifier for the codex entry.
  final String id;

  /// The title of the entry.
  final String title;

  /// The category of the entry (e.g., Medical, Finance).
  final String category;

  /// The type of the entry (e.g., Simulation, Course, Peer).
  final String type; // Simulation, Course, Peer

  /// Creates a [CodexEntry] instance.
  CodexEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
  });
}

/// Service that indexes and searches across all Verasso modules (Simulations, Courses, Social).
class CodexSearchService {
  /// Creates a [CodexSearchService] instance.
  CodexSearchService();
  final List<CodexEntry> _index = [
    CodexEntry(
        id: 'lab_pharmacy',
        title: 'Pharmacy Formulation Lab',
        category: 'Medical',
        type: 'Simulation'),
    CodexEntry(
        id: 'course_fin_101',
        title: 'Sovereign Finance 101',
        category: 'Finance',
        type: 'Course'),
    CodexEntry(
        id: 'sim_ar_surg',
        title: 'AR Surgical Assistant',
        category: 'Medical',
        type: 'Simulation'),
    CodexEntry(
        id: 'social_mentor_1',
        title: 'Senior Mesh Mentor',
        category: 'Social',
        type: 'Peer'),
  ];

  /// Searches the codex for a given [query].
  List<CodexEntry> search(String query) {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _index
        .where((entry) =>
            entry.title.toLowerCase().contains(lowercaseQuery) ||
            entry.category.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}
