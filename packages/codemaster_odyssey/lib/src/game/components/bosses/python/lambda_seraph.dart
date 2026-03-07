import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../../engine/combat/boss_patterns.dart';
import '../boss_component.dart';

/// Region 1 Boss: Garden of Scripts
class LambdaSeraph extends BossComponent {
  double patternTimer = 0;

  final double patternInterval = 3.0;
  final AttackPattern _beamStrike = BeamStrike();
  LambdaSeraph({super.position}) : super(maxHealth: 500);

  @override
  void onDefeated() {
    debugPrint('Lambda Seraph: Function safely terminated.');
    super.onDefeated();
  }

  @override
  void onHealthChanged() {
    // Phase 1 -> 2 transition
    if (state == BossState.phase1 && currentHealth < maxHealth * 0.7) {
      state = BossState.phase2;
      debugPrint('Lambda Seraph: Entering Phase 2 (Self-Modification)!');
    }

    // Trigger code challenge at very low health
    if (state == BossState.phase2 && currentHealth < maxHealth * 0.3) {
      triggerCodeChallenge();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final spriteSheet = await game.images.load('lambda_seraph.png');
      animation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.1,
          textureSize: Vector2.all(128), // Bosses might be larger
        ),
      );
    } catch (e) {
      debugPrint('Error loading LambdaSeraph animation: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state == BossState.phase1 || state == BossState.phase2) {
      patternTimer += dt;
      if (patternTimer >= patternInterval) {
        _executePattern();
        patternTimer = 0;
      }
    }
  }

  void _executePattern() {
    if (state == BossState.phase1) {
      _beamStrike.execute(this, 0);
    } else if (state == BossState.phase2) {
      // Phase 2: Double Beam or Lambda Split
      _beamStrike.execute(this, 0);
      _fireLambdaSplit();
    }
  }

  void _fireLambdaSplit() {
    debugPrint('Lambda Seraph: Lambda Split!');
    // Spawn transient components or extra projectiles
  }
}
