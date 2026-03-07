import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../combat/combat_actions.dart';
import '../progression/powerup_system.dart';

/// Manages the persistence and state of Aria's progression.
class PlayerState extends ChangeNotifier {
  /// Code fragments collected (currency/XP).
  int fragments = 0;

  /// Player level.
  int level = 1;

  /// Current health.
  double health = 100.0;

  /// Maximum health.
  double maxHealth = 100.0;

  /// Current region (1-25).
  int currentRegion = 1;

  /// Unlocked Language Arcs.
  final Set<LanguageArc> unlockedArcs = {LanguageArc.python};

  /// Active Powerups/Items.
  final List<PowerupEffect> activeEffects = [];

  /// Returns the current language arc based on the region.
  LanguageArc get currentArc {
    if (currentRegion <= 5) return LanguageArc.python;
    if (currentRegion <= 10) return LanguageArc.java;
    if (currentRegion <= 15) return LanguageArc.javascript;
    if (currentRegion <= 20) return LanguageArc.cpp;
    return LanguageArc.sql;
  }

  /// Adds fragments and handles level-up logic.
  void addFragments(int amount) {
    fragments += amount;
    if (fragments >= level * 100) {
      level++;
      maxHealth += 10;
      health = maxHealth;
    }
    notifyListeners();
  }

  /// Adds a powerup effect, preventing duplicates.
  void addPowerup(PowerupEffect effect) {
    if (activeEffects.any((e) => e.id == effect.id)) return;
    activeEffects.add(effect);
    notifyListeners();
  }

  /// Heals the player by [amount], clamped to max.
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
    notifyListeners();
  }

  /// Loads state from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('odyssey_save');
    if (json == null) return;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      fragments = (data['fragments'] as num?)?.toInt() ?? 0;
      level = (data['level'] as num?)?.toInt() ?? 1;
      health = (data['health'] as num?)?.toDouble() ?? 100.0;
      maxHealth = (data['maxHealth'] as num?)?.toDouble() ?? 100.0;
      currentRegion = (data['currentRegion'] as num?)?.toInt() ?? 1;

      final arcIndex = (data['arcIndex'] as num?)?.toInt() ?? 0;
      unlockedArcs.clear();
      for (int i = 0; i <= arcIndex; i++) {
        unlockedArcs.add(LanguageArc.values[i]);
      }

      notifyListeners();
    } catch (_) {
      // Corrupted save — start fresh
    }
  }

  /// Advances to the next region.
  void nextRegion() {
    currentRegion++;
    // Unlock new arc when crossing arc boundaries
    if (currentRegion == 6) unlockedArcs.add(LanguageArc.java);
    if (currentRegion == 11) unlockedArcs.add(LanguageArc.javascript);
    if (currentRegion == 16) unlockedArcs.add(LanguageArc.cpp);
    if (currentRegion == 21) unlockedArcs.add(LanguageArc.sql);
    notifyListeners();
  }

  /// Removes a powerup by ID.
  void removePowerup(String id) {
    activeEffects.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Saves state to SharedPreferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'fragments': fragments,
      'level': level,
      'health': health,
      'maxHealth': maxHealth,
      'currentRegion': currentRegion,
      'arcIndex': unlockedArcs.length - 1,
    };
    await prefs.setString('odyssey_save', jsonEncode(data));
  }

  /// Applies damage to the player, clamped to 0.
  void takeDamage(double amount) {
    health = (health - amount).clamp(0, maxHealth);
    notifyListeners();
  }

  /// Unlocks a language arc.
  void unlockArc(LanguageArc arc) {
    unlockedArcs.add(arc);
    notifyListeners();
  }
}
