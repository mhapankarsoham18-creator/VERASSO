import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'components/player/aria_player.dart';
import 'engine/audio/audio_manager.dart';
import 'engine/progression/player_state.dart';
import 'engine/progression/region_manager.dart';
import 'ui/mobile_hud.dart';

/// The core game class for Codemaster Odyssey.
class OdysseyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  /// The player character.
  late final AriaPlayer player;

  /// The player's progression state.
  late final PlayerState state;

  /// Manages region loading and transitions.
  late final RegionManager regionManager;

  /// Shared RNG for spawning and effects.
  final Random random = Random();

  /// Virtual joystick reference (set by HUD).
  JoystickComponent? joystick;

  /// Data for the current code challenge overlay.
  Map<String, dynamic> currentChallengeData = {};

  /// Current region number for the transition overlay.
  int transitionRegion = 1;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Pause on Escape
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (overlays.isActive('PauseMenu')) {
        overlays.remove('PauseMenu');
        resumeEngine();
      } else {
        pauseEngine();
        overlays.add('PauseMenu');
      }
      return KeyEventResult.handled;
    }

    final isHandled = super.onKeyEvent(event, keysPressed);
    if (isHandled == KeyEventResult.handled) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload all valid character sprite sheets
    await images.loadAll([
      'characters/aria/aria_idle.png',
      'characters/aria/aria_run.png',
      'characters/aria/aria_attack.png',
      'characters/aria/player_white_jacket.png',
      'characters/aria/player_biker.png',
      'characters/aria/player_leather.png',
      'characters/aria/player_purple.png',
      'characters/aria/player_racing.png',
      'characters/enemies/python/variable_viper.png',
      'characters/enemies/python/syntax_error_enemy.png',
      'characters/enemies/python/recursion_raven.png',
      'characters/enemies/python/looping_lynx.png',
      'characters/enemies/python/class_chimera.png',
      'characters/bosses/lambda_seraph.png',
      'characters/lyra/lyra.png',
    ]);

    state = PlayerState();
    await state.load(); // Load saved progress

    regionManager = RegionManager();
    add(regionManager);

    player = AriaPlayer(position: Vector2.all(100));
    world.add(player);
    camera.follow(player);

    // Add HUD
    final hud = MobileHUD();
    add(hud);
    joystick = hud.joystick;

    // Start region BGM
    AudioManager.playRegionTheme(state.currentRegion);

    // Load initial region content
    regionManager.loadCurrentRegion();
  }

  /// Called after the player completes a code challenge.
  void resumeAfterChallenge() {
    AudioManager.playChallengeComplete();
    resumeEngine();
  }

  /// Saves the current game state.
  Future<void> saveState() async {
    await state.save();
  }

  /// Triggers a code challenge overlay with the given data.
  void showCodeChallenge(Map<String, dynamic> data) {
    currentChallengeData = data;
    pauseEngine();
    overlays.add('CodeChallenge');
  }

  /// Shows a region transition screen with the region name.
  void showRegionTransition(int region) {
    transitionRegion = region;
    AudioManager.playRegionTheme(region);
    overlays.add('RegionTransition');

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlays.remove('RegionTransition');
    });
  }
}
