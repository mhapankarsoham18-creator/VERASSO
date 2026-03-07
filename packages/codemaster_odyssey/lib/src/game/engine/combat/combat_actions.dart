/// Defines a combat action (basic or special attack).
class CombatAction {
  final String name;
  final double damage;
  final double cooldown;
  final String description;
  final String? animationKey;

  const CombatAction({
    required this.name,
    required this.damage,
    required this.cooldown,
    required this.description,
    this.animationKey,
  });
}

/// Manager for player attacks based on the active Language Arc.
class CombatSystem {
  static Map<LanguageArc, List<CombatAction>> getArcActions() {
    return {
      LanguageArc.python: [
        const CombatAction(
          name: 'Indent Strike',
          damage: 15,
          cooldown: 0.5,
          description: 'A rapid combo based on perfect indentation.',
        ),
        const CombatAction(
          name: 'List Comprehension',
          damage: 40,
          cooldown: 3.0,
          description: 'An AoE burst that hits all surrounding enemies.',
        ),
      ],
      LanguageArc.java: [
        const CombatAction(
          name: 'Override Parry',
          damage: 10,
          cooldown: 1.0,
          description: 'Counter an attack with strict typing precision.',
        ),
        const CombatAction(
          name: 'Try-Catch Shield',
          damage: 0,
          cooldown: 5.0,
          description: 'Absorbs the next incoming exception (attack).',
        ),
      ],
      // Add other arcs here...
    };
  }
}

/// The 5 Language Arcs of the game.
enum LanguageArc { python, java, javascript, cpp, sql }
