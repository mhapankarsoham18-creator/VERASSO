import 'package:flutter/material.dart';

import '../domain/academic_skill_model.dart';

/// A list tile widget that displays an [AcademicSkill] and its verification status.
class SkillVerificationTile extends StatelessWidget {
  /// The skill data to display.
  final AcademicSkill skill;

  /// Creates a [SkillVerificationTile] widget.
  const SkillVerificationTile({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2E).withValues(alpha: 0.5),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSubjectColor().withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(_getSubjectIcon(), color: _getSubjectColor()),
        ),
        title: Text(
          skill.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          skill.subject,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: skill.mastery > 0.7
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            skill.mastery > 0.7 ? 'VERIFIED' : 'IN PROGRESS',
            style: TextStyle(
              color: skill.mastery > 0.7 ? Colors.green : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor() {
    switch (skill.subject.toLowerCase()) {
      case 'chemistry':
        return Colors.greenAccent;
      case 'physics':
        return Colors.blueAccent;
      case 'history':
        return Colors.amberAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  IconData _getSubjectIcon() {
    switch (skill.subject.toLowerCase()) {
      case 'chemistry':
        return Icons.biotech;
      case 'physics':
        return Icons.bolt;
      case 'history':
        return Icons.auto_stories;
      default:
        return Icons.school;
    }
  }
}
