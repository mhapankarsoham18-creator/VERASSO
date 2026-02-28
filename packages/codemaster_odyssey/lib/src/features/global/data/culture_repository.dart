import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cultural_theme_model.dart';

/// Provider for the [CultureRepository], which manages available cultural themes.
final cultureProvider =
    NotifierProvider<CultureRepository, List<CulturalTheme>>(
      CultureRepository.new,
    );

/// Repository responsible for providing and managing cultural realms.
class CultureRepository extends Notifier<List<CulturalTheme>> {
  @override
  List<CulturalTheme> build() {
    return [
      const CulturalTheme(
        id: 'mayan',
        name: 'Mayan Math',
        description: 'Solve base-20 puzzles in ancient temples.',
        primaryColor: Colors.orangeAccent,
        icon: Icons.castle,
      ),
      const CulturalTheme(
        id: 'tokyo',
        name: 'Cyber Tokyo',
        description: 'Neon-infused async programming in futuristic towers.',
        primaryColor: Colors.cyanAccent,
        icon: Icons.settings_input_component,
      ),
      const CulturalTheme(
        id: 'medieval',
        name: 'Medieval Logic',
        description: 'Defend castles with boolean predicates.',
        primaryColor: Colors.redAccent,
        icon: Icons.security,
      ),
    ];
  }
}
