import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [GenerativeLabService] instance.
final generativeLabServiceProvider = Provider((ref) => GenerativeLabService());

/// Service that proceduraly generates unique laboratory scenarios using AI-like logic.
class GenerativeLabService {
  /// Creates a [GenerativeLabService] instance.
  GenerativeLabService();
  final Random _random = Random();

  /// Generates a new scenario based on the user's current progress and desired [complexity].
  LabScenario generateScenario({String complexity = 'Medium'}) {
    final subjects = [
      'Ophthalmic Solution',
      'Pediatric Suspension',
      'Topical Gel',
      'Sustained Release Tablet'
    ];
    final subject = subjects[_random.nextInt(subjects.length)];

    final stabilityTargets = {
      'Low': 0.75,
      'Medium': 0.88,
      'High': 0.95,
      'Master': 0.99,
    };

    final target = stabilityTargets[complexity] ?? 0.85;

    final scenario = LabScenario(
      title: 'Advanced $subject Formulation',
      description:
          'Design a stable $subject with a target stability of ${(target * 100).toInt()}%. Watch for pH sensitivity.',
      targetStability: target,
      requiredExcipients: ['Lactose', 'Polymer X', 'Thermal Stabilizer'],
      complexity: complexity,
    );

    AppLogger.info(
        'GenerativeLab: Generated unique scenario: ${scenario.title}');
    return scenario;
  }
}

/// Represents a procedurally generated laboratory scenario.
class LabScenario {
  /// The title of the lab scenario.
  final String title;

  /// A detailed description of the scenario.
  final String description;

  /// The target stability percentage to achieve.
  final double targetStability;

  /// The list of required excipients for the formulation.
  final List<String> requiredExcipients;

  /// The complexity level of the scenario.
  final String complexity;

  /// Creates a [LabScenario] instance.
  LabScenario({
    required this.title,
    required this.description,
    required this.targetStability,
    required this.requiredExcipients,
    required this.complexity,
  });
}
