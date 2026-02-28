import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/ui/glass_container.dart';
import '../../data/talent_profile_model.dart';

/// Widget that displays or edits the header of a talent profile.
class TalentProfileHeader extends StatelessWidget {
  /// The talent profile.
  final TalentProfile profile;

  /// Whether the header is in editing mode.
  final bool isEditing;

  /// Controller for the headline text field.
  final TextEditingController headlineController;

  /// Optional badge widget to display (e.g., Karma).
  final Widget? karmaBadge;

  /// Optional rating row widget.
  final Widget? ratingRow;

  /// Creates a [TalentProfileHeader].
  const TalentProfileHeader({
    super.key,
    required this.profile,
    required this.isEditing,
    required this.headlineController,
    this.karmaBadge,
    this.ratingRow,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(LucideIcons.user, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(profile.fullName ?? profile.username ?? 'User',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (isEditing)
            TextField(
              controller: headlineController,
              decoration: const InputDecoration(
                  hintText: 'Headline (e.g. Senior Artist)'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
            )
          else
            Text(profile.headline ?? 'New Talent',
                style: const TextStyle(fontSize: 16, color: Colors.blueAccent)),
          if (karmaBadge != null) ...[
            const SizedBox(height: 12),
            karmaBadge!,
          ],
          if (ratingRow != null) ...[
            const SizedBox(height: 12),
            ratingRow!,
          ],
        ],
      ),
    );
  }
}
