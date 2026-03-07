import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../odyssey_game.dart';
import '../collectibles/collectible_component.dart';

/// A simple enemy component for testing combat.
class DummyEnemy extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  double health = 50.0;

  final double moveSpeed = 50.0;
  DummyEnemy({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(32));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFFF0000));
    }
    super.render(canvas);
  }

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      _onDefeated();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Simple chase AI
    final playerPos = game.player.position;
    final direction = playerPos - position;
    if (direction.length > 5) {
      direction.normalize();
      position.add(direction * moveSpeed * dt);
    }
  }

  void _onDefeated() {
    // Drop loot: 50% chance for Code Fragment, 20% for Health Patch
    final rand = game.random;
    if (rand.nextDouble() < 0.7) {
      game.world.add(CodeFragment(position: position.clone()));
    } else if (rand.nextDouble() < 0.2) {
      game.world.add(DebugPatch(position: position.clone()));
    }

    removeFromParent();
  }
}
