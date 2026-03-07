import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../engine/audio/audio_manager.dart';
import '../../odyssey_game.dart';
import '../player/aria_player.dart';

/// A fragment of code dropped by enemies (Currency/XP).
class CodeFragment extends CollectibleComponent {
  CodeFragment({super.position});

  @override
  void onCollected() {
    game.state.addFragments(10);
    AudioManager.playSFX('collect.wav');
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 4,
        Paint()..color = const Color(0xFF00E5FF).withAlpha(200),
      );
    }
    super.render(canvas);
  }
}

/// Base class for all collectible items in the world.
abstract class CollectibleComponent extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  CollectibleComponent({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(32));

  /// Define what happens when Aria collects this item.
  void onCollected();

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AriaPlayer) {
      onCollected();
      removeFromParent();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    // Add a gentle floating effect
    add(
      MoveEffect.by(
        Vector2(0, -10),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}

/// A small debug patch that heals the player.
class DebugPatch extends CollectibleComponent {
  DebugPatch({super.position});

  @override
  void onCollected() {
    game.state.heal(20);
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      canvas.drawRect(
        size.toRect().deflate(8),
        Paint()..color = const Color(0xFF00FF00).withAlpha(200),
      );
    }
    super.render(canvas);
  }
}
