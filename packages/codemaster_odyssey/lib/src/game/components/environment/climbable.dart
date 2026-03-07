import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../odyssey_game.dart';

/// A climbable zone (like a ladder or vine) where the player can move vertically ignoring gravity.
class Climbable extends PositionComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  Climbable({required super.position, required super.size});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(isSolid: true));
  }

  @override
  void render(Canvas canvas) {
    // Basic ladder representation
    final paint = Paint()
      ..color =
          const Color(0xFF8B4513) // SaddleBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw vertical rails
    canvas.drawLine(
      Offset(size.x * 0.2, 0),
      Offset(size.x * 0.2, size.y),
      paint,
    );
    canvas.drawLine(
      Offset(size.x * 0.8, 0),
      Offset(size.x * 0.8, size.y),
      paint,
    );

    // Draw horizontal rungs
    for (double i = 20; i < size.y; i += 30) {
      canvas.drawLine(Offset(size.x * 0.2, i), Offset(size.x * 0.8, i), paint);
    }
  }
}
