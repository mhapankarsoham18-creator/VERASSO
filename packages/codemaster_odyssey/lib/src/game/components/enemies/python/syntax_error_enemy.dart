import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../odyssey_game.dart';
import '../../../ui/damage_text.dart';
import '../../collectibles/collectible_component.dart';
import '../../../engine/progression/loot_system.dart';

/// A fast, erratic enemy representing a Python syntax error.
class SyntaxErrorEnemy extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  /// Enemy health.
  double health = 30.0;

  /// Movement speed.
  final double moveSpeed = 120.0;

  /// Internal timer for glitch effect.
  double glitchTimer = 0.0;

  /// Creates a [SyntaxErrorEnemy].
  SyntaxErrorEnemy({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(32));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    try {
      final spriteSheet = await game.images.load('syntax_error_enemy.png');
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.08,
          textureSize: Vector2.all(32),
        ),
      );
    } catch (_) {
      // Fallback to procedural rendering
    }
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      final color = glitchTimer % 0.2 < 0.1
          ? const Color(0xFF800080)
          : const Color(0xFFFF0000);
      canvas.drawRect(size.toRect(), Paint()..color = color);
    }
    super.render(canvas);
  }

  /// Applies damage with popup and handles defeat.
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
    glitchTimer += dt;

    final playerPos = game.player.position;
    final direction = playerPos - position;

    if (glitchTimer % 1.5 < 0.2) {
      position.add(direction.normalized() * 10);
    }

    if (direction.length > 5) {
      direction.normalize();
      position.add(direction * moveSpeed * dt);
    }
  }

  void _onDefeated() {
    // Random loot drops
    LootSystem.spawnDrops(game, position, dropChance: 0.4, maxDrops: 2);

    // Guaranteed fragment
    if (game.random.nextDouble() < 0.5) {
      game.world.add(CodeFragment(position: position.clone()));
    }
    removeFromParent();
  }
}
