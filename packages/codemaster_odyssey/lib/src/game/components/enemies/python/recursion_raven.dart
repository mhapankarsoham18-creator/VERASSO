import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../../odyssey_game.dart';

/// A Region 4 enemy that mirrors its own movements and creates "recursive" echoes.
class RecursionRaven extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  double health = 60.0;
  final double moveSpeed = 100.0;
  double _timer = 0.0;
  final List<Vector2> _pathHistory = [];
  final int maxHistory = 60; // 1 second @ 60fps

  RecursionRaven({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(40));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    try {
      final spriteSheet = await game.images.load('recursion_raven.png');
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.1,
          textureSize: Vector2.all(40),
        ),
      );
    } catch (e) {
      debugPrint('Error loading RecursionRaven animation: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2,
        Paint()..color = const Color(0xFF191970), // Midnight Blue
      );
    }
    super.render(canvas);

    // Render "Recursive Echoes"
    if (_pathHistory.isNotEmpty) {
      final paint = Paint()
        ..color = const Color(0x4D191970); // Semi-transparent
      for (int i = 0; i < _pathHistory.length; i += 15) {
        final echoPos = _pathHistory[i] - position;
        canvas.drawCircle(
          Offset(echoPos.x + size.x / 2, echoPos.y + size.y / 2),
          (size.x / 2) * (i / _pathHistory.length),
          paint,
        );
      }
    }
  }

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Movement: Sine wave approach
    final playerPos = game.player.position;
    final direction = (playerPos - position).normalized();
    final perpendicular = Vector2(-direction.y, direction.x);

    final waveOffset = math.sin(_timer * 3) * 100;
    final velocity = direction * moveSpeed + perpendicular * waveOffset;

    position.add(velocity * dt);

    // Track path history for recursive visual
    _pathHistory.add(position.clone());
    if (_pathHistory.length > maxHistory) {
      _pathHistory.removeAt(0);
    }

    // Occasional "Recursion" - Spawn a transient clone
    if (_timer > 5.0 && game.random.nextDouble() < 0.01) {
      _timer = 0;
      _spawnRecursiveClone();
    }
  }

  void _spawnRecursiveClone() {
    // A simplified clone that just moves straight and fades out
    final clone = RecursiveClone(
      position: position.clone(),
      velocity: (game.player.position - position).normalized() * 200,
    );
    game.world.add(clone);
  }
}

class RecursiveClone extends PositionComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  final Vector2 velocity;
  double lifespan = 2.0;

  RecursiveClone({required super.position, required this.velocity})
    : super(size: Vector2.all(20));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final opacity = (lifespan / 2.0).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Color.fromRGBO(25, 25, 112, opacity),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);
    lifespan -= dt;

    if (lifespan <= 0) {
      removeFromParent();
    }

    if (position.distanceTo(game.player.position) < 20) {
      game.player.takeDamage(5);
      removeFromParent();
    }
  }
}
