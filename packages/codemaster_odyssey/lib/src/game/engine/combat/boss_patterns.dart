import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../components/bosses/boss_component.dart';
import '../../odyssey_game.dart';

/// Represents a reusable attack pattern for bosses.
abstract class AttackPattern {
  void execute(BossComponent boss, double dt);
}

/// A linear beam of energy aimed at the player.
class BeamStrike extends AttackPattern {
  final double damage;
  final double speed;

  BeamStrike({this.damage = 10, this.speed = 300});

  @override
  void execute(BossComponent boss, double dt) {
    final player = boss.game.player;
    final direction = (player.position - boss.position).normalized();

    final projectile = Projectile(
      position: boss.position.clone(),
      velocity: direction * speed,
      damage: damage,
      color: const Color(0xFF00E5FF),
    );
    boss.game.world.add(projectile);
  }
}

/// A basic projectile component used by boss patterns.
class Projectile extends CircleComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  final Vector2 velocity;
  final double damage;
  final Color color;

  Projectile({
    required Vector2 position,
    required this.velocity,
    required this.damage,
    this.color = const Color(0xFFFF0000),
  }) : super(position: position, radius: 8, paint: Paint()..color = color);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);

    // Remove if off screen (approximate)
    if (position.x < -100 ||
        position.x > 2000 ||
        position.y < -100 ||
        position.y > 2000) {
      removeFromParent();
    }
  }
}
