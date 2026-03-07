import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../../odyssey_game.dart';

/// A Region 3 enemy that moves in circular "loops".
class LoopingLynx extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  double health = 50.0;
  final double speed = 150.0;
  double _angle = 0.0;
  final double _radius = 50.0;
  late Vector2 _center;

  LoopingLynx({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(40)) {
    _center = position.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    try {
      final spriteSheet = await game.images.load('looping_lynx.png');
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.1,
          textureSize: Vector2.all(40),
        ),
      );
    } catch (e) {
      debugPrint('Error loading LoopingLynx animation: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
        Paint()..color = const Color(0xFFFFA500), // Orange
      );
    }
    super.render(canvas);
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
    _angle += speed * dt / _radius;

    // Movement pattern: Move towards player while looping
    final playerPos = game.player.position;
    final direction = (playerPos - _center).normalized();
    _center.add(direction * (speed * 0.5) * dt);

    position.setValues(
      _center.x + math.cos(_angle) * _radius,
      _center.y + math.sin(_angle) * _radius,
    );
  }
}
