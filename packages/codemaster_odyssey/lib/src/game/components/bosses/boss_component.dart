import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../../engine/combat/python_challenges.dart';
import '../../engine/progression/loot_system.dart';
import '../../odyssey_game.dart';
import '../../ui/damage_text.dart';
import '../collectibles/collectible_component.dart';

/// Base class for all 25 bosses in the game.
abstract class BossComponent extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, CollisionCallbacks {
  /// Maximum health for this boss.
  final double maxHealth;

  /// Current health.
  late double currentHealth;

  /// Current boss state machine phase.
  BossState state = BossState.intro;

  /// Creates a [BossComponent] with [maxHealth].
  BossComponent({required this.maxHealth, super.position, Vector2? size})
    : super(size: size ?? Vector2.all(128));

  /// Override this to handle defeat animations and rewards.
  void onDefeated() {
    // Bosses drop guaranteed high-value loot (more drops, higher chance)
    LootSystem.spawnDrops(game, position, dropChance: 1.0, maxDrops: 5);

    // Also drop guaranteed fragments
    for (int i = 0; i < 5; i++) {
      game.world.add(
        CodeFragment(
          position: position.clone()
            ..add(
              Vector2(
                (game.random.nextDouble() - 0.5) * 100,
                (game.random.nextDouble() - 0.5) * 100,
              ),
            ),
        ),
      );
    }
    game.world.add(DebugPatch(position: position.clone()));

    removeFromParent();
  }

  /// Override this to handle phase transitions and health-based logic.
  void onHealthChanged();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    currentHealth = maxHealth;
    add(RectangleHitbox());

    state = BossState.phase1;
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFFF4444));

      // Boss name tag
      final healthBarWidth = size.x;
      final healthPercentage = currentHealth / maxHealth;

      // Health bar background
      canvas.drawRect(
        Rect.fromLTWH(0, -20, healthBarWidth, 10),
        Paint()..color = const Color(0x44000000),
      );
      // Health bar fill
      final healthColor = healthPercentage > 0.5
          ? const Color(0xFFFF0000)
          : healthPercentage > 0.25
          ? const Color(0xFFFF8800)
          : const Color(0xFFFF0044);
      canvas.drawRect(
        Rect.fromLTWH(0, -20, healthBarWidth * healthPercentage, 10),
        Paint()..color = healthColor,
      );
    }
    super.render(canvas);
  }

  /// Applies damage and triggers phase changes.
  void takeDamage(double damage) {
    if (state == BossState.defeated) return;

    currentHealth -= damage;

    // Show damage popup
    game.world.add(
      DamageText(
        damage: damage,
        position: position.clone()..add(Vector2(0, -size.y / 2)),
        isCritical: damage > 30,
      ),
    );

    onHealthChanged();

    if (currentHealth <= 0) {
      currentHealth = 0;
      state = BossState.defeated;
      onDefeated();
    }
  }

  /// Triggers a code challenge overlay, pausing the boss fight.
  void triggerCodeChallenge() {
    state = BossState.codeChallenge;
    final challenge = PythonChallenges.getChallenge(game.state.currentRegion);
    game.showCodeChallenge(challenge);
  }
}

/// Boss state machine phases.
enum BossState {
  /// Intro cinematic.
  intro,

  /// First attack phase.
  phase1,

  /// Enraged phase.
  phase2,

  /// Final phase.
  phase3,

  /// Paused for code challenge.
  codeChallenge,

  /// Boss defeated.
  defeated,
}
