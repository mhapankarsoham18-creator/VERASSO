import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../odyssey_game.dart';
import '../../../ui/damage_text.dart';
import '../../../engine/progression/loot_system.dart';
import '../../collectibles/collectible_component.dart';

/// A snake-themed enemy that tracks variables and changes tactics.
class VariableViper extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  /// Enemy health.
  double health = 40.0;

  /// Base movement speed.
  final double moveSpeed = 80.0;

  /// Internal timer for behavior switching.
  double _behaviorTimer = 0.0;

  /// Whether the viper is in aggressive mode.
  bool _aggressive = false;

  /// Tracks which "variable" the viper has adopted (cosmetic state).
  int _variableState = 0;

  /// Creates a [VariableViper].
  VariableViper({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(36));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    try {
      final spriteSheet = await game.images.load('variable_viper.png');
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.12,
          textureSize: Vector2.all(36),
        ),
      );
    } catch (_) {
      // Fallback to procedural rendering
    }
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      // Color changes with variable state
      final colors = [
        const Color(0xFF228B22), // Forest Green
        const Color(0xFF006400), // Dark Green
        const Color(0xFF32CD32), // Lime Green
      ];
      canvas.drawRect(
        size.toRect(),
        Paint()..color = colors[_variableState % colors.length],
      );

      // Health bar
      final hpPercent = health / 40.0;
      canvas.drawRect(
        Rect.fromLTWH(0, -8, size.x, 4),
        Paint()..color = const Color(0x44000000),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, -8, size.x * hpPercent, 4),
        Paint()..color = const Color(0xFFFF0000),
      );
    }
    super.render(canvas);
  }

  /// Applies damage with popup.
  void takeDamage(double damage) {
    health -= damage;

    game.world.add(
      DamageText(
        damage: damage,
        position: position.clone()..add(Vector2(0, -size.y / 2)),
      ),
    );

    if (health <= 0) {
      _onDefeated();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _behaviorTimer += dt;

    // Switch behavior every 3 seconds ("reassign variable")
    if (_behaviorTimer > 3.0) {
      _behaviorTimer = 0;
      _aggressive = !_aggressive;
      _variableState = (_variableState + 1) % 3;
    }

    final playerPos = game.player.position;
    final direction = (playerPos - position);

    if (_aggressive && direction.length > 5) {
      // Aggressive: chase fast
      direction.normalize();
      position.add(direction * moveSpeed * 1.5 * dt);
    } else if (direction.length > 5) {
      // Passive: slow approach with weaving
      direction.normalize();
      final weave =
          Vector2(-direction.y, direction.x) *
          ((_behaviorTimer * 4).remainder(1.0) > 0.5 ? 1 : -1) *
          30;
      position.add((direction * moveSpeed * 0.5 + weave) * dt);
    }
  }

  void _onDefeated() {
    LootSystem.spawnDrops(game, position, dropChance: 0.45, maxDrops: 2);
    if (game.random.nextDouble() < 0.6) {
      game.world.add(CodeFragment(position: position.clone()));
    }
    removeFromParent();
  }
}
