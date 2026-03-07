import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../odyssey_game.dart';

/// A non-playable character that dispenses story or lore when the player is near.
class StoryNPC extends PositionComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  final String npcName;
  final String initialDialogue;
  bool isPlayerNear = false;

  StoryNPC({
    required this.npcName,
    required this.initialDialogue,
    required super.position,
    Vector2? size,
  }) : super(size: size ?? Vector2.all(48));

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other == game.player) {
      isPlayerNear = true;
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other == game.player) {
      isPlayerNear = false;
    }
    super.onCollisionEnd(other);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Use a larger hitbox to detect player proximity
    add(
      RectangleHitbox(
        size: Vector2(size.x * 3, size.y * 2),
        position: Vector2(-size.x, -size.y),
        isSolid: false,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Placeholder rendering for NPC
    final paint = Paint()
      ..color =
          const Color(0xFF9C27B0) // Purple for NPCs
      ..style = PaintingStyle.fill;
    canvas.drawRect(size.toRect(), paint);

    if (isPlayerNear) {
      // Draw a simple speech bubble indicator
      final bubblePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-50, -40, 150, 30),
          const Radius.circular(8),
        ),
        bubblePaint,
      );

      const textStyle = TextStyle(
        color: Colors.black,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      );
      final textSpan = TextSpan(
        text: '$npcName:\n$initialDialogue',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: 140);
      textPainter.paint(canvas, const Offset(-45, -35));
    }
  }
}
