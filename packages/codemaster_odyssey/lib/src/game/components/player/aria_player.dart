import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../engine/combat/combat_actions.dart';
import '../../odyssey_game.dart';
import '../../ui/damage_text.dart';
import '../bosses/boss_component.dart';
import '../enemies/dummy_enemy.dart';
import '../environment/climbable.dart';
import '../environment/terrain_block.dart';

/// The main character Aria Vale.
class AriaPlayer extends SpriteAnimationComponent
    with HasGameReference<OdysseyGame>, KeyboardHandler, CollisionCallbacks {
  final double baseMoveSpeed = 200.0;
  final double jumpForce = 400.0;
  final double gravity = 800.0;

  double bonusMoveSpeed = 0.0;
  final Vector2 velocity = Vector2.zero();
  bool isAttacking = false;

  // Platformer State
  bool isOnGround = false;
  bool isClimbing = false;

  double attackTimer = 0.0;
  CombatAction? activeAction;
  // Dodge mechanics
  bool isDodging = false;

  double dodgeTimer = 0.0;
  final double dodgeDuration = 0.2;
  final double dodgeMultiplier = 3.0;
  // Stat modifiers (updated by powerups)
  double defenseMultiplier = 1.0;

  double rangeMultiplier = 1.0;

  String _currentCostume = '';

  AriaPlayer({super.position, Vector2? size})
    : super(size: size ?? Vector2.all(64));

  void attack(int index) {
    if (isAttacking || isDodging) return;

    final arc = game.state.currentArc;
    final actions = CombatSystem.getArcActions()[arc];
    if (actions == null || index >= actions.length) return;

    activeAction = actions[index];
    isAttacking = true;

    final baseRange = index == 0 ? 80.0 : 150.0;
    final attackRange = baseRange * rangeMultiplier;

    for (final enemy in game.world.children.whereType<DummyEnemy>()) {
      if (position.distanceTo(enemy.position) < attackRange) {
        enemy.takeDamage(activeAction!.damage);
      }
    }

    for (final boss in game.world.children.whereType<BossComponent>()) {
      if (position.distanceTo(boss.position) < attackRange) {
        boss.takeDamage(activeAction!.damage);
      }
    }
  }

  void dodge() {
    if (isDodging || isAttacking || velocity.x == 0) return;
    isDodging = true;
    dodgeTimer = 0;
  }

  void jump() {
    if (isOnGround && !isClimbing && !isAttacking && !isDodging) {
      velocity.y = -jumpForce;
      isOnGround = false;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is TerrainBlock) {
      // Basic top collision detection
      if (velocity.y > 0 && position.y + size.y / 2 < other.position.y) {
        isOnGround = true;
        velocity.y = 0;
        position.y = other.position.y - size.y;
      }
    } else if (other is Climbable) {
      isClimbing = true;
      isOnGround = false; // Climbing overrides ground check
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Climbable) {
      isClimbing = false;
      velocity.y = 0;
    }
    super.onCollisionEnd(other);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      attack(0);
    } else if (keysPressed.contains(LogicalKeyboardKey.keyE)) {
      attack(1);
    } else if (keysPressed.contains(LogicalKeyboardKey.shiftLeft)) {
      dodge();
    } else if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      jump();
    }

    final bool left =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final bool right =
        keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);
    final bool up =
        keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp);
    final bool down =
        keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown);

    // X-axis movement
    if (!isAttacking && !isDodging) {
      if (left) {
        velocity.x = -(baseMoveSpeed + bonusMoveSpeed);
      } else if (right) {
        velocity.x = (baseMoveSpeed + bonusMoveSpeed);
      } else {
        velocity.x = 0;
      }

      if (isClimbing) {
        if (up) {
          velocity.y = -(baseMoveSpeed + bonusMoveSpeed);
        } else if (down) {
          velocity.y = (baseMoveSpeed + bonusMoveSpeed);
        } else {
          velocity.y = 0;
        }
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    // Initial costume for current region
    await updateCostume(game.state.currentRegion);
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFFFD700));

      // HP Bar (Aria)
      final hpPercentage = game.state.health / game.state.maxHealth;
      canvas.drawRect(
        Rect.fromLTWH(0, -15, size.x, 5),
        Paint()..color = const Color(0x44000000),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, -15, size.x * hpPercentage, 5),
        Paint()..color = const Color(0xFF00FF00),
      );

      if (isDodging) {
        canvas.drawRect(
          size.toRect().inflate(10),
          Paint()
            ..color = const Color(0x44FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      if (isAttacking && activeAction != null) {
        final radius =
            (activeAction!.name == 'Indent Strike' ? 40.0 : 100.0) *
            rangeMultiplier;
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          radius,
          Paint()..color = const Color(0x88FFFFFF),
        );
      }
    }
    super.render(canvas);
  }

  void takeDamage(double amount) {
    if (isDodging) return; // Invincible during dodge

    final actualDamage = amount / defenseMultiplier;
    game.state.takeDamage(actualDamage);

    // Show damage popup on Aria
    game.world.add(
      DamageText(
        damage: actualDamage,
        position: position.clone()..add(Vector2(0, -size.y)),
      ),
    );

    // Death check
    if (game.state.health <= 0) {
      _onDeath();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check if dead
    if (game.state.health <= 0) return;

    // reset multipliers for this frame (passive powerups will re-apply)
    defenseMultiplier = 1.0;
    rangeMultiplier = 1.0;
    bonusMoveSpeed = 0.0;

    // Update active powerups
    for (final effect in game.state.activeEffects) {
      effect.onUpdate(this, dt);
    }

    if (isDodging) {
      dodgeTimer += dt;
      if (dodgeTimer >= dodgeDuration) {
        isDodging = false;
        dodgeTimer = 0;
      }
      position.add(
        Vector2(velocity.x.sign, 0) *
            (baseMoveSpeed + bonusMoveSpeed) *
            dt *
            dodgeMultiplier,
      );
      return;
    }

    if (isAttacking) {
      attackTimer += dt;
      if (activeAction != null && attackTimer >= activeAction!.cooldown) {
        isAttacking = false;
        attackTimer = 0;
        activeAction = null;
      }
    }

    // Calculate Target Velocity from Joystick or Keyboard
    double targetVelX = velocity.x;
    double targetVelY = velocity.y;

    if (game.joystick != null && game.joystick!.isDragged) {
      targetVelX =
          game.joystick!.relativeDelta.x * (baseMoveSpeed + bonusMoveSpeed);
      if (isClimbing) {
        targetVelY =
            game.joystick!.relativeDelta.y * (baseMoveSpeed + bonusMoveSpeed);
      }
    } else {
      // If joystick is resting, and we want to fall back to keyboard:
      // Since velocity is updated in onKeyEvent, it's safe to use it.
      // But if the player releases joystick, the dragged state becomes false.
      // And velocity.x might still hold an old keyboard value. We assume keyboard users don't use joystick.
      targetVelX = velocity.x;
      // Climbing: if not dragged & no keyboard, stop.
      if (isClimbing && velocity.y == 0) {
        targetVelY = 0;
      }
    }

    // Apply Gravity
    if (!isClimbing) {
      targetVelY += gravity * dt;
    }

    // Assign final velocity
    velocity.x = targetVelX;
    velocity.y = targetVelY;

    // Apply Velocity
    position.add(velocity * dt);

    // Simple ground floor safety (prevent falling forever until Terrain blocks are placed)
    if (position.y > 600) {
      position.y = 600;
      velocity.y = 0;
      isOnGround = true;
    } else {
      // Very basic air check
      if (position.y < 600) {
        isOnGround = false;
      }
    }
  }

  Future<void> updateCostume(int region) async {
    // 1-5: Costume 1
    // 6-10: Costume 2
    // etc.
    final costumeIndex = ((region - 1) / 5).floor() + 1;
    String newCostume;

    switch (costumeIndex) {
      case 1:
        newCostume = 'characters/aria/player_white_jacket.png';
        break;
      case 2:
        newCostume = 'characters/aria/player_biker.png';
        break;
      case 3:
        newCostume = 'characters/aria/player_leather.png';
        break;
      case 4:
        newCostume = 'characters/aria/player_purple.png';
        break;
      case 5:
        newCostume = 'characters/aria/player_racing.png';
        break;
      default:
        newCostume = 'characters/aria/player_white_jacket.png';
    }

    if (_currentCostume != newCostume) {
      _currentCostume = newCostume;
      try {
        final spriteSheet = await game.images.load(_currentCostume);
        animation = SpriteAnimation.fromFrameData(
          spriteSheet,
          SpriteAnimationData.sequenced(
            amount: 4,
            stepTime: 0.1,
            textureSize: Vector2.all(64),
          ),
        );
      } catch (e) {
        debugPrint('Error loading costume $_currentCostume: $e');
        // Fallback to placeholder if not found
        animation = null;
      }
    }
  }

  /// Handles player death: lose half fragments, respawn at region start.
  void _onDeath() {
    // Penalty: lose half fragments
    game.state.fragments = (game.state.fragments / 2).floor();

    // Restore health
    game.state.health = game.state.maxHealth;

    // Respawn at region start
    position.setValues(100, 500);
    velocity.setZero();
    isOnGround = false;
    isClimbing = false;
    isAttacking = false;
    isDodging = false;

    // Reload the region (re-spawn enemies)
    game.regionManager.loadCurrentRegion();
  }
}
