import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'odyssey_game.dart';
import 'ui/challenge_widget.dart';
import 'ui/codedex_overlay.dart';
import 'ui/region_transition_overlay.dart';

/// The main game screen wrapper for Codemaster Odyssey.
class OdysseyGameScreen extends ConsumerStatefulWidget {
  /// Creates the [OdysseyGameScreen].
  const OdysseyGameScreen({super.key});

  @override
  ConsumerState<OdysseyGameScreen> createState() => _OdysseyGameScreenState();
}

class _OdysseyGameScreenState extends ConsumerState<OdysseyGameScreen> {
  late final OdysseyGame _game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'PauseMenu': (context, OdysseyGame game) => _buildPauseMenu(context),
          'Codedex': (context, OdysseyGame game) =>
              CodedexOverlay(onClose: () => game.overlays.remove('Codedex')),
          'CodeChallenge': (context, OdysseyGame game) => CodeChallengeWidget(
            challengeData: game.currentChallengeData,
            onSolve: () {
              game.state.addFragments(50);
              game.overlays.remove('CodeChallenge');
              game.resumeAfterChallenge();
            },
            onWrongAnswer: () {
              // Penalty: lose 10 HP on wrong answer
              game.state.takeDamage(10);
            },
          ),
          'RegionTransition': (context, OdysseyGame game) =>
              RegionTransitionOverlay(game: game),
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Flame.device.setLandscape();
    _game = OdysseyGame();
  }

  Widget _buildPauseMenu(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            border: Border.all(color: Colors.cyan, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              _pauseButton('Resume', Icons.play_arrow, () {
                _game.overlays.remove('PauseMenu');
                _game.resumeEngine();
              }),
              const SizedBox(height: 12),
              _pauseButton('Save & Quit', Icons.save, () {
                _game.saveState();
                Navigator.of(context).pop();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.cyan),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.cyan),
        label: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
