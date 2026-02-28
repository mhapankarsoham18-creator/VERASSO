import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/talent_profile_model.dart';

/// Widget that displays or edits the experience section of a talent profile.
class TalentExperienceList extends StatelessWidget {
  /// List of experience entries.
  final List<ExperienceEntry> experience;

  /// Whether the list is in editing mode.
  final bool isEditing;

  /// Callback when an item is removed.
  final Function(int) onRemove;

  /// Creates a [TalentExperienceList].
  const TalentExperienceList({
    super.key,
    required this.experience,
    required this.isEditing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (experience.isEmpty) {
      return const Text('No experience listed.',
          style: TextStyle(color: Colors.white38));
    }
    return Column(
      children: experience
          .asMap()
          .entries
          .map((entry) => _ExperienceItem(
                entry.value,
                entry.key,
                isEditing,
                onRemove,
              ))
          .toList(),
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  final ExperienceEntry e;
  final int index;
  final bool isEditing;
  final Function(int) onRemove;

  const _ExperienceItem(this.e, this.index, this.isEditing, this.onRemove);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.briefcase, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(e.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(LucideIcons.trash2,
                            size: 14, color: Colors.redAccent),
                        onPressed: () => onRemove(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                Text(e.company,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 13)),
                Text('${e.startDate ?? ""} - ${e.endDate ?? "Present"}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
                if (e.description != null) ...[
                  const SizedBox(height: 4),
                  Text(e.description!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
