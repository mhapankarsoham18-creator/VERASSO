import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../../odyssey_game.dart';

enum ChimeraMode { lion, snake, goat }

class ChimeraPoison extends PositionComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  final Vector2 velocity;

  ChimeraPoison({required super.position, required this.velocity})
    : super(size: Vector2.all(8));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = const Color(0xFF00FF00),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);

    if (position.distanceTo(game.player.position) < 15) {
      game.player.takeDamage(15);
      removeFromParent();
    }

    if (position.length > 2000) {
      removeFromParent();
    }
  }
}

/// A Region 5 hybrid enemy with multiple attack modes.
class ClassChimera extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  double health = 80.0;
  final double moveSpeed = 80.0;
  ChimeraMode mode = ChimeraMode.lion;
  double modeTimer = 0.0;

  ClassChimera({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(48));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    try {
      final spriteSheet = await game.images.load('class_chimera.png');
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.1,
          textureSize: Vector2.all(48),
        ),
      );
    } catch (e) {
      debugPrint('Error loading ClassChimera animation: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      Color color;
      switch (mode) {
        case ChimeraMode.lion:
          color = const Color(0xFFFFD700); // Gold
          break;
        case ChimeraMode.snake:
          color = const Color(0xFF2E8B57); // Sea Green
          break;
        case ChimeraMode.goat:
          color = const Color(0xFF8B4513); // Saddle Brown
          break;
      }
      canvas.drawRect(size.toRect(), Paint()..color = color);

      // Simple visual indicator for "heads"
      final paint = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawCircle(Offset(size.x * 0.2, 5), 5, paint);
      canvas.drawCircle(Offset(size.x * 0.5, 5), 5, paint);
      canvas.drawCircle(Offset(size.x * 0.8, 5), 5, paint);
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
    modeTimer += dt;

    if (modeTimer > 4.0) {
      modeTimer = 0;
      _switchMode();
    }

    final playerPos = game.player.position;
    final direction = playerPos - position;

    switch (mode) {
      case ChimeraMode.lion:
        _updateLionMode(dt, direction);
        break;
      case ChimeraMode.snake:
        _updateSnakeMode(dt, direction);
        break;
      case ChimeraMode.goat:
        _updateGoatMode(dt, direction);
        break;
    }
  }

  void _shootPoison() {
    // Simple poison projectile logic
    final projectile = ChimeraPoison(
      position: position.clone(),
      velocity: (game.player.position - position).normalized() * 250,
    );
    game.world.add(projectile);
  }

  void _switchMode() {
    final nextIndex = (mode.index + 1) % ChimeraMode.values.length;
    mode = ChimeraMode.values[nextIndex];
  }

  void _updateGoatMode(double dt, Vector2 direction) {
    // Slow approach, then quick dash
    if (modeTimer < 2.0) {
      position.add(direction.normalized() * moveSpeed * 0.5 * dt);
    } else if (modeTimer < 2.5) {
      // Dash
      position.add(direction.normalized() * moveSpeed * 3.0 * dt);
    }
  }

  void _updateLionMode(double dt, Vector2 direction) {
    // Aggressive chase
    if (direction.length > 5) {
      position.add(direction.normalized() * moveSpeed * 1.5 * dt);
    }
  }

  void _updateSnakeMode(double dt, Vector2 direction) {
    // Keep distance and shoot
    if (direction.length < 250) {
      position.add(-direction.normalized() * moveSpeed * dt);
    }

    if (modeTimer % 2.0 < 0.02) {
      _shootPoison();
    }
  }
}
