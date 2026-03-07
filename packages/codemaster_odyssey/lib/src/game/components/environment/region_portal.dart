import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../odyssey_game.dart';
import '../player/aria_player.dart';
import '../../engine/progression/codemaster_sync_service.dart';

/// A portal that appears after defeating all enemies in a region.
/// When the player touches it, they advance to the next region.
class RegionPortal extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  RegionPortal({super.position})
    : super(size: Vector2(64, 96), anchor: Anchor.center);

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AriaPlayer) {
      game.state.nextRegion();
      game.saveState(); // Local save
      game.regionManager.loadCurrentRegion();

      // Fire and forget remote sync
      CodemasterSyncService().syncState(game.state);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    // Placeholder animation until asset is provided
    try {
      final spriteSheet = await game.images.load('region_portal.png');
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.1,
          textureSize: Vector2(64, 96),
        ),
      );
    } catch (_) {
      // Fallback is just an empty component or logic to advance
    }
  }
}
