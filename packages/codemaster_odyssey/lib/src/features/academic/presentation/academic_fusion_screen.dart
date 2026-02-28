import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/academic_repository.dart';
import 'science_simulation_widget.dart';
import 'skill_verification_tile.dart';

/// Main screen for the Academic Fusion feature, showcasing simulations and verified skills.
class AcademicFusionScreen extends ConsumerWidget {
  /// Creates an [AcademicFusionScreen] widget.
  const AcademicFusionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicSkills = ref.watch(academicRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ACADEMIC FUSION CENTER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ScienceSimulationWidget(subject: 'Chemistry', progress: 0.8),
          const SizedBox(height: 16),
          const Text(
            'VERIFIED SKILLS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...academicSkills.map((skill) => SkillVerificationTile(skill: skill)),
          const SizedBox(height: 24),
          const ScienceSimulationWidget(subject: 'Physics', progress: 0.6),
          const SizedBox(height: 16),
          const ScienceSimulationWidget(subject: 'History', progress: 0.4),
        ],
      ),
    );
  }
}
