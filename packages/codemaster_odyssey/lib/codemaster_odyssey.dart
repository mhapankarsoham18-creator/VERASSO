/// CodeMaster Odyssey — A gamified coding education module for VERASSO.
///
/// This package provides a complete coding education experience through
/// an RPG-style world map with realms, challenges, multiplayer duels,
/// mentorship, and enterprise certification features.
///
/// ## Quick Start
/// ```dart
/// import 'package:codemaster_odyssey/codemaster_odyssey.dart';
///
/// // Embed in your app:
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const OdysseyMapScreen(),
/// ));
///
/// // Or run standalone:
/// runApp(const CodemasterOdysseyApp());
/// ```
///
/// ## Features
/// - **Map & Realms**: Fantasy world map with realm progression
/// - **Lessons**: 90-second micro-lessons with instant feedback
/// - **Editor**: Odyssey IDE with syntax highlighting
/// - **AI Tutor**: Contextual hints and submission analysis
/// - **Challenges**: 75+ multi-technology coding challenges
/// - **Avatar**: Customizable character with skill trees
/// - **Badges**: Achievement celebrations
/// - **Quests**: Daily quests with streak multipliers
/// - **Multiplayer**: Code duels and mesh collaboration
/// - **Collaboration**: Mentorship and classroom analytics
/// - **Academic**: Cross-module linking with science/history
/// - **Enterprise**: ZK identity proofs and certifications
/// - **Global**: Cultural themes and community hub
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/features/map/presentation/odyssey_map_screen.dart';

// ── Core ──────────────────────────────────────────────────────────────
export 'src/core/theme/odyssey_colors.dart';
// ── Features (Public API) ─────────────────────────────────────────────
export 'src/features/academic/academic.dart';
export 'src/features/ai_tutor/ai_tutor.dart';
export 'src/features/avatar/avatar.dart';
export 'src/features/badge/badge.dart';
export 'src/features/challenge/challenge.dart';
export 'src/features/collaboration/collaboration.dart';
export 'src/features/editor/editor.dart';
export 'src/features/enterprise/enterprise.dart';
export 'src/features/global/global.dart';
export 'src/features/lesson/lesson.dart';
export 'src/features/map/map.dart';
export 'src/features/multiplayer/multiplayer.dart';
export 'src/features/quest/quest.dart';

/// The main entry widget for the CodeMaster Odyssey module.
///
/// Can be embedded into the main app or run standalone for testing.
/// When embedded, assumes the parent provides a [ProviderScope].
class CodemasterOdysseyApp extends StatelessWidget {
  /// Creates a [CodemasterOdysseyApp] instance.
  const CodemasterOdysseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00E5FF),
        ),
      ),
      home: const ProviderScope(child: OdysseyMapScreen()),
    );
  }
}
