import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/talent_profile_model.dart';

/// Widget that displays or edits the education section of a talent profile.
class TalentEducationList extends StatelessWidget {
  /// List of education entries.
  final List<EducationEntry> education;

  /// Whether the list is in editing mode.
  final bool isEditing;

  /// Callback when an Item is removed.
  final Function(int) onRemove;

  /// Creates a [TalentEducationList].
  const TalentEducationList({
    super.key,
    required this.education,
    required this.isEditing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (education.isEmpty) {
      return const Text('No education listed.',
          style: TextStyle(color: Colors.white38));
    }
    return Column(
      children: education
          .asMap()
          .entries
          .map((entry) => _EducationItem(
                entry.value,
                entry.key,
                isEditing,
                onRemove,
              ))
          .toList(),
    );
  }
}

class _EducationItem extends StatelessWidget {
  final EducationEntry e;
  final int index;
  final bool isEditing;
  final Function(int) onRemove;

  const _EducationItem(this.e, this.index, this.isEditing, this.onRemove);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.graduationCap,
              size: 20, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(e.school,
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
                Text(e.degree,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 13)),
                if (e.startDate != null)
                  Text('${e.startDate} - ${e.endDate ?? "Present"}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
