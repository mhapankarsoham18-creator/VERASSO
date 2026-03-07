import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../odyssey_game.dart';

/// A static terrain block representing the floor or walls.
class TerrainBlock extends PositionComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  TerrainBlock({required super.position, required super.size});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(isSolid: true));
  }

  @override
  void render(Canvas canvas) {
    // Basic terrain appearance (can be overridden by Stitch sprites later)
    final paint = Paint()
      ..color =
          const Color(0xFF228B22) // ForestGreen
      ..style = PaintingStyle.fill;
    canvas.drawRect(size.toRect(), paint);
  }
}
