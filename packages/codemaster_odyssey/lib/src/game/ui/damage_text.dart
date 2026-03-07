import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A floating damage number that drifts upward and fades out.
class DamageText extends TextComponent {
  /// Creates a floating [DamageText].
  DamageText({
    required double damage,
    required Vector2 position,
    bool isCritical = false,
  }) : super(
          text: '-${damage.toInt()}',
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: isCritical ? const Color(0xFFFF4444) : Colors.white,
              fontSize: isCritical ? 20.0 : 14.0,
              fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
              shadows: const [
                Shadow(offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Float upward
    add(
      MoveEffect.by(
        Vector2(0, -40),
        EffectController(duration: 0.8, curve: Curves.easeOut),
      ),
    );

    // Fade out and remove
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.8),
        onComplete: removeFromParent,
      ),
    );
  }
}

/// A floating heal number (green, drifts up).
class HealText extends TextComponent {
  /// Creates a floating [HealText].
  HealText({
    required double amount,
    required Vector2 position,
  }) : super(
          text: '+${amount.toInt()}',
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      MoveEffect.by(
        Vector2(0, -30),
        EffectController(duration: 0.6, curve: Curves.easeOut),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.6),
        onComplete: removeFromParent,
      ),
    );
  }
}

/// A floating loot pickup text (rarity-colored).
class LootPickupText extends TextComponent {
  /// Creates a floating [LootPickupText].
  LootPickupText({
    required String itemName,
    required Color rarityColor,
    required Vector2 position,
  }) : super(
          text: itemName,
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: rarityColor,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      MoveEffect.by(
        Vector2(0, -50),
        EffectController(duration: 1.2, curve: Curves.easeOut),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 1.2),
        onComplete: removeFromParent,
      ),
    );
  }
}
