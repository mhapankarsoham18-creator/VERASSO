import 'package:flutter/material.dart';

/// Widget that displays or edits the bio section of a talent profile.
class TalentBioSection extends StatelessWidget {
  /// The current bio text.
  final String? bio;
  /// Whether the section is in editing mode.
  final bool isEditing;
  /// Controller for the bio text field.
  final TextEditingController bioController;

  /// Creates a [TalentBioSection].
  const TalentBioSection({
    super.key,
    this.bio,
    required this.isEditing,
    required this.bioController,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return TextField(
        controller: bioController,
        maxLines: 3,
        decoration: const InputDecoration(
            hintText: 'Tell us about your professional background...'),
      );
    }
    return Text(bio ?? 'No bio provided.',
        style: const TextStyle(color: Colors.white70));
  }
}
