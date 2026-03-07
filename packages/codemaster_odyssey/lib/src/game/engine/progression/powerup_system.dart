import 'package:flame/extensions.dart';

import '../../components/player/aria_player.dart';

/// Defines a buff or tool effect applied to the player.
abstract class PowerupEffect {
  final String id;
  final String name;
  final String description;

  PowerupEffect({
    required this.id,
    required this.name,
    required this.description,
  });

  void onApply(AriaPlayer player);
  void onRemove(AriaPlayer player);
  void onUpdate(AriaPlayer player, double dt) {}
}

/// Range Increase (C++ Arc Tool: Pointer Gauntlet)
class RangeGauntlet extends PowerupEffect {
  RangeGauntlet()
    : super(
        id: 'pointer_gauntlet',
        name: 'Pointer Gauntlet',
        description: 'Increases attack range by 25%.',
      );

  @override
  void onApply(AriaPlayer player) {
    // Logic to increase attackRange variable in Player
  }

  @override
  void onRemove(AriaPlayer player) {
    // Reset range
  }
}

/// Standstill Defense Buff (Java Arc Tool: Interface Circlet)
class StandstillDefense extends PowerupEffect {
  bool _isApplied = false;

  StandstillDefense()
    : super(
        id: 'interface_circlet',
        name: 'Interface Circlet',
        description: 'Doubles defense when standing still.',
      );

  @override
  void onApply(AriaPlayer player) {}

  @override
  void onRemove(AriaPlayer player) {
    // Reset if removed
    if (_isApplied) {
      // player.defense /= 2;
    }
  }

  @override
  void onUpdate(AriaPlayer player, double dt) {
    if (player.velocity.isZero()) {
      if (!_isApplied) {
        // player.defense *= 2;
        _isApplied = true;
      }
    } else {
      if (_isApplied) {
        // player.defense /= 2;
        _isApplied = false;
      }
    }
  }
}
