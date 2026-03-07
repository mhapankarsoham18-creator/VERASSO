/// CodeMaster Odyssey — A 2D Pixel-Art Coding Action RPG for VERASSO.
library;

import 'package:flutter/material.dart';

import 'src/game/odyssey_game_screen.dart';

export 'src/features/lesson/data/history_providers.dart';
export 'src/game/components/player/aria_player.dart';
export 'src/game/odyssey_game.dart';
export 'src/game/odyssey_game_screen.dart';

/// The main entry widget for the CodeMaster Odyssey module.
class CodemasterOdysseyApp extends StatelessWidget {
  const CodemasterOdysseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      ),
      home: const OdysseyGameScreen(),
    );
  }
}
