import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../components/collectibles/collectible_component.dart';
import '../../odyssey_game.dart';

/// A world component representing a dropped loot item.
class LootDrop extends CollectibleComponent {
  /// The loot item this drop represents.
  final LootItem item;

  /// Creates a [LootDrop].
  LootDrop({required this.item, super.position});

  @override
  void onCollected() {
    if (item.fragmentValue > 0) {
      game.state.addFragments(item.fragmentValue);
    }
    if (item.healAmount > 0) {
      game.state.heal(item.healAmount);
    }
    // Powerup effects would be applied via PowerupSystem here
  }

  @override
  void render(Canvas canvas) {
    if (animation == null) {
      // Draw a glowing orb with rarity color
      final paint = Paint()..color = item.rarity.color.withAlpha(220);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 3, paint);

      // Inner glow
      final innerPaint = Paint()..color = item.rarity.color.withAlpha(100);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, innerPaint);
    }
    super.render(canvas);
  }
}

/// Defines a specific loot item that can drop.
class LootItem {
  /// Display name of the item.
  final String name;

  /// Rarity tier.
  final LootRarity rarity;

  /// Fragments rewarded on pickup.
  final int fragmentValue;

  /// Health restored on pickup (0 for non-healing items).
  final double healAmount;

  /// Whether this item grants a temporary powerup.
  final bool isPowerup;

  /// Duration of the powerup effect in seconds (if applicable).
  final double powerupDuration;

  /// Creates a [LootItem].
  const LootItem({
    required this.name,
    required this.rarity,
    this.fragmentValue = 0,
    this.healAmount = 0,
    this.isPowerup = false,
    this.powerupDuration = 0,
  });
}

/// Defines the rarity tiers for loot drops.
enum LootRarity {
  /// Common drops (white) — 60% chance.
  common(Color(0xFFCCCCCC), 0.60),

  /// Uncommon drops (green) — 25% chance.
  uncommon(Color(0xFF00FF00), 0.25),

  /// Rare drops (blue) — 10% chance.
  rare(Color(0xFF4488FF), 0.10),

  /// Epic drops (purple) — 4% chance.
  epic(Color(0xFFAA44FF), 0.04),

  /// Legendary drops (gold) — 1% chance.
  legendary(Color(0xFFFFD700), 0.01);

  /// The display color for this rarity tier.
  final Color color;

  /// The probability weight for this tier.
  final double weight;

  const LootRarity(this.color, this.weight);
}

/// Manages the loot table and random drop generation.
class LootSystem {
  static final Random _rng = Random();

  /// Master loot table for the Python Arc.
  static const List<LootItem> pythonLootTable = [
    // Common
    LootItem(
      name: 'Code Fragment',
      rarity: LootRarity.common,
      fragmentValue: 10,
    ),
    LootItem(
      name: 'Small Debug Patch',
      rarity: LootRarity.common,
      healAmount: 10,
    ),
    LootItem(name: 'Syntax Token', rarity: LootRarity.common, fragmentValue: 5),

    // Uncommon
    LootItem(
      name: 'Logic Shard',
      rarity: LootRarity.uncommon,
      fragmentValue: 25,
    ),
    LootItem(name: 'Debug Patch', rarity: LootRarity.uncommon, healAmount: 25),
    LootItem(
      name: 'Indent Boost',
      rarity: LootRarity.uncommon,
      isPowerup: true,
      powerupDuration: 10,
    ),

    // Rare
    LootItem(
      name: 'Algorithm Core',
      rarity: LootRarity.rare,
      fragmentValue: 50,
    ),
    LootItem(name: 'Full Restore', rarity: LootRarity.rare, healAmount: 100),
    LootItem(
      name: 'Speed Compile',
      rarity: LootRarity.rare,
      isPowerup: true,
      powerupDuration: 15,
    ),

    // Epic
    LootItem(
      name: 'Lambda Crystal',
      rarity: LootRarity.epic,
      fragmentValue: 100,
    ),
    LootItem(
      name: 'Exception Shield',
      rarity: LootRarity.epic,
      isPowerup: true,
      powerupDuration: 20,
    ),

    // Legendary
    LootItem(
      name: 'The Zen of Python',
      rarity: LootRarity.legendary,
      fragmentValue: 500,
    ),
  ];

  /// Generates a list of loot drops for a defeated enemy.
  ///
  /// [dropChance] is the base probability (0.0-1.0) that *any* loot drops.
  /// [maxDrops] is the maximum number of items that can drop.
  /// [region] influences the loot table used.
  static List<LootItem> rollDrops({
    double dropChance = 0.5,
    int maxDrops = 3,
    int region = 1,
  }) {
    final drops = <LootItem>[];

    // Each potential drop slot has its own chance
    for (int i = 0; i < maxDrops; i++) {
      // Diminishing returns on extra drops
      final slotChance = dropChance * (1.0 / (i + 1));
      if (_rng.nextDouble() > slotChance) continue;

      final rarity = _rollRarity();
      final candidates = pythonLootTable
          .where((item) => item.rarity == rarity)
          .toList();

      if (candidates.isNotEmpty) {
        drops.add(candidates[_rng.nextInt(candidates.length)]);
      }
    }

    return drops;
  }

  /// Spawns loot drop components at the given position.
  static void spawnDrops(
    OdysseyGame game,
    Vector2 position, {
    double dropChance = 0.5,
    int maxDrops = 3,
  }) {
    final drops = rollDrops(
      dropChance: dropChance,
      maxDrops: maxDrops,
      region: game.state.currentRegion,
    );

    for (int i = 0; i < drops.length; i++) {
      final item = drops[i];
      final offset = Vector2(
        (game.random.nextDouble() - 0.5) * 80,
        (game.random.nextDouble() - 0.5) * 80,
      );

      if (item.healAmount > 0) {
        game.world.add(
          LootDrop(item: item, position: position.clone()..add(offset)),
        );
      } else {
        game.world.add(
          LootDrop(item: item, position: position.clone()..add(offset)),
        );
      }
    }
  }

  /// Rolls a random rarity tier.
  static LootRarity _rollRarity() {
    final roll = _rng.nextDouble();
    double cumulative = 0;
    for (final rarity in LootRarity.values) {
      cumulative += rarity.weight;
      if (roll <= cumulative) return rarity;
    }
    return LootRarity.common;
  }
}
