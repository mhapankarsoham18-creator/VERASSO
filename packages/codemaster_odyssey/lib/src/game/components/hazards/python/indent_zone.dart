import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../odyssey_game.dart';

/// A hazard zone that penalizes non-cardinal movement (strict indentation).
class IndentZone extends PositionComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  IndentZone({super.position, super.size});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Subtle grid or green lines to indicate indentation
    final paint = Paint()
      ..color = const Color(0x3300FF00)
      ..style = PaintingStyle.fill;
    canvas.drawRect(size.toRect(), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final player = game.player;
    if (containsPoint(player.position)) {
      final vel = player.velocity;
      // If moving diagonally (not "indented" correctly), slow down
      if (vel.x.abs() > 0.1 && vel.y.abs() > 0.1) {
        player.bonusMoveSpeed -= 100.0;
      }
    }
  }
}
