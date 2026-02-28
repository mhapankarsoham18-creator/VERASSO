import 'package:flutter/material.dart';

/// Widget that displays or edits the skills section of a talent profile.
class TalentSkillsChips extends StatelessWidget {
  /// List of skills.
  final List<String> skills;

  /// Whether the section is in editing mode.
  final bool isEditing;

  /// Controller for the skills text field.
  final TextEditingController skillsController;

  /// Creates a [TalentSkillsChips].
  const TalentSkillsChips({
    super.key,
    required this.skills,
    required this.isEditing,
    required this.skillsController,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return TextField(
        controller: skillsController,
        decoration: const InputDecoration(
            hintText: 'Skills (e.g. Photoshop, Flutter, Python)'),
      );
    }
    return Wrap(
      spacing: 8,
      children: skills
          .map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white10,
              ))
          .toList(),
    );
  }
}
