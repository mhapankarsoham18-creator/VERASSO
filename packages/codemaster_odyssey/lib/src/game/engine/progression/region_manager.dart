import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../../components/bosses/python/lambda_seraph.dart';
import '../../components/enemies/python/class_chimera.dart';
import '../../components/enemies/python/looping_lynx.dart';
import '../../components/enemies/python/recursion_raven.dart';
import '../../components/enemies/python/syntax_error_enemy.dart';
import '../../components/enemies/python/variable_viper.dart';
import '../../components/environment/climbable.dart';
import '../../components/environment/region_portal.dart';
import '../../components/environment/terrain_block.dart';
import '../../components/hazards/python/indent_zone.dart';
import '../../components/npcs/story_npc.dart';
import '../../components/player/aria_player.dart';
import '../../odyssey_game.dart';
import '../combat/difficulty_config.dart';

/// Configures and manages the content of game regions.
class RegionManager extends Component with HasGameReference<OdysseyGame> {
  final List<Component> _activeEnemies = [];
  bool _portalSpawned = false;

  /// Loads the content for the current region based on the player state.
  Future<void> loadCurrentRegion() async {
    final state = game.state;
    final region = state.currentRegion;

    _clearWorld();
    _portalSpawned = false;
    _activeEnemies.clear();

    game.player.updateCostume(region);

    // Show transition overlay
    game.showRegionTransition(region);

    if (region <= 5) {
      await _loadPythonRegion(region);
    } else {
      // Future regions (Java, etc.)
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_portalSpawned && _activeEnemies.isNotEmpty) {
      _activeEnemies.removeWhere((e) => !e.isMounted);

      if (_activeEnemies.isEmpty) {
        _portalSpawned = true;
        game.world.add(RegionPortal(position: Vector2(400, 300)));
      }
    }
  }

  void _clearWorld() {
    game.world.children
        .where(
          (c) =>
              c is! PositionComponent ||
              (c is! AriaPlayer && c is! RegionPortal),
        )
        .forEach((c) => c.removeFromParent());
  }

  Map<String, dynamic> _getDefaultRegionConfig(int region) {
    return {
      "npc": {
        "name": "Guide",
        "dialogue": "Welcome to Region $region!",
        "position": {"x": 50, "y": 552},
      },
      "enemyType": "SyntaxErrorEnemy",
      "platformCount": 4 + region,
      "hazardSizeMultiplier": 1,
    };
  }

  Future<Map<String, dynamic>> _getRegionConfig(int region) async {
    try {
      final jsonString = await rootBundle.loadString(
        'packages/codemaster_odyssey/assets/data/regions.json',
      );
      final data = json.decode(jsonString);
      return data['regions'][region.toString()] ??
          _getDefaultRegionConfig(region);
    } catch (e) {
      return _getDefaultRegionConfig(region);
    }
  }

  Future<void> _loadPythonRegion(int region) async {
    final diffConfig = DifficultyConfig.forRegion(region);
    final config = await _getRegionConfig(region);

    // Base floor
    game.world.add(
      TerrainBlock(position: Vector2(-1000, 600), size: Vector2(3000, 200)),
    );

    // Platforms from JSON
    if (config.containsKey('platforms')) {
      final List<dynamic> platforms = config['platforms'];
      for (final p in platforms) {
        game.world.add(
          TerrainBlock(
            position: Vector2(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
            ),
            size: Vector2(
              (p['w'] as num).toDouble(),
              (p['h'] as num).toDouble(),
            ),
          ),
        );
      }
    }

    // Ladder
    game.world.add(
      Climbable(position: Vector2(300, 350), size: Vector2(40, 250)),
    );

    // Indent Zone hazard
    final hazardMult = config['hazardSizeMultiplier'] as num;
    game.world.add(
      IndentZone(
        position: Vector2(200, 200),
        size: Vector2(300.0 + (hazardMult * 40), 300.0 + (hazardMult * 40)),
      ),
    );

    // Story NPC
    final npcData = config['npc'];
    game.world.add(
      StoryNPC(
        npcName: npcData['name']!,
        initialDialogue: npcData['dialogue']!,
        position: Vector2(
          (npcData['position']['x'] as num).toDouble(),
          (npcData['position']['y'] as num).toDouble(),
        ),
      ),
    );

    // Enemies
    for (int i = 0; i < diffConfig.enemyCount; i++) {
      final pos = Vector2(
        100 + game.random.nextDouble() * 800,
        100 + game.random.nextDouble() * 300,
      );

      Component enemy;
      final type = config['enemyType'] as String;
      switch (type) {
        case 'VariableViper':
          enemy = VariableViper(position: pos);
          break;
        case 'LoopingLynx':
          enemy = LoopingLynx(position: pos);
          break;
        case 'RecursionRaven':
          enemy = RecursionRaven(position: pos);
          break;
        case 'ClassChimera':
          enemy = ClassChimera(position: pos);
          break;
        case 'SyntaxErrorEnemy':
        default:
          enemy = SyntaxErrorEnemy(position: pos);
          break;
      }
      game.world.add(enemy);
      _activeEnemies.add(enemy);
    }

    // Boss
    if (config.containsKey('bossType')) {
      final boss = LambdaSeraph(position: Vector2(500, 300));
      game.world.add(boss);
      _activeEnemies.add(boss);
    }
  }
}
