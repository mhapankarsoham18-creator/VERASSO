import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A custom painter for visualizing historical battle scenarios and tactics.
class BattlePainter extends CustomPainter {
  /// The current progress of the battle animation.
  final double progress;

  /// The tactic chosen by the player.
  final Tactic playerTactic;

  /// The tactic used by the enemy.
  final Tactic enemyTactic;

  /// The specific battle scenario being simulated.
  final BattleScenario scenario;

  /// Creates a [BattlePainter] instance.
  BattlePainter({
    required this.progress,
    required this.playerTactic,
    required this.enemyTactic,
    required this.scenario,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final playerPaint = Paint()..color = Colors.blueAccent;
    final enemyPaint = Paint()..color = Colors.redAccent;

    // Simple Dot Representation of Units
    // Player starts at bottom, Enemy at top

    // Player Units
    _drawUnits(canvas, size, playerPaint, isPlayer: true);

    // Enemy Units
    _drawUnits(canvas, size, enemyPaint, isPlayer: false);
  }

  @override
  bool shouldRepaint(covariant BattlePainter oldDelegate) => true;

  void _drawUnits(Canvas canvas, Size size, Paint paint,
      {required bool isPlayer}) {
    final startY = isPlayer ? size.height * 0.8 : size.height * 0.2;
    final forwardY = isPlayer ? -1.0 : 1.0; // Direction multiplier
    final tactic = isPlayer ? playerTactic : enemyTactic;

    // Movement calculation based on progress
    double moveDist = size.height * 0.3 * progress;

    if (tactic == Tactic.charge) {
      // Center mass moving forward
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 3; j++) {
          double dx = size.width * 0.4 + (i * 15);
          double dy = startY + (j * 10 * forwardY) + (moveDist * forwardY);
          canvas.drawCircle(Offset(dx, dy), 4, paint);
        }
      }
    } else if (tactic == Tactic.defense) {
      // Holding line, minimal movement
      for (int i = 0; i < 8; i++) {
        double dx = size.width * 0.2 + (i * 25);
        double dy = startY + (moveDist * 0.2 * forwardY); // Move slightly
        canvas.drawRect(
            Rect.fromCenter(center: Offset(dx, dy), width: 10, height: 10),
            paint);
      }
    } else if (tactic == Tactic.flank) {
      // Split forces
      // Center holding
      for (int i = 0; i < 3; i++) {
        double dx = size.width * 0.45 + (i * 15);
        double dy = startY + (moveDist * 0.5 * forwardY);
        canvas.drawCircle(Offset(dx, dy), 4, paint);
      }
      // Wings moving fast and wide
      double wingProgress = moveDist * 1.5;
      double wingWide = size.width * 0.3 * progress;

      // Left Wing
      canvas.drawCircle(
          Offset(
              size.width * 0.3 - wingWide, startY + (wingProgress * forwardY)),
          5,
          paint);
      canvas.drawCircle(
          Offset(
              size.width * 0.35 - wingWide, startY + (wingProgress * forwardY)),
          5,
          paint);

      // Right Wing
      canvas.drawCircle(
          Offset(
              size.width * 0.7 + wingWide, startY + (wingProgress * forwardY)),
          5,
          paint);
      canvas.drawCircle(
          Offset(
              size.width * 0.65 + wingWide, startY + (wingProgress * forwardY)),
          5,
          paint);
    }
  }
}

/// Represents a specific historical battle scenario with strategic parameters.
class BattleScenario {
  /// The name of the battle.
  final String name;

  /// The year the battle occurred.
  final String year;

  /// A description of the battle context.
  final String description;

  /// The name of the player's side.
  final String playerSide;

  /// The name of the enemy's side.
  final String enemySide;

  /// The tactic used by the enemy in the simulation.
  final Tactic enemyTactic;

  /// The optimal tactic that leads to player victory.
  final Tactic optimalTactic;

  /// Creates a [BattleScenario] instance.
  BattleScenario({
    required this.name,
    required this.year,
    required this.description,
    required this.playerSide,
    required this.enemySide,
    required this.enemyTactic,
    required this.optimalTactic,
  });
}

/// Military tactics available in the war strategy simulation.
enum Tactic {
  /// Direct frontal assault.
  charge,

  /// Defensive posture to minimize losses.
  defense,

  /// Maneuvering to attack the enemy's side or rear.
  flank
}

/// A screen for simulating historical battles and testing different military strategies.
class WarStrategyScreen extends StatefulWidget {
  /// Creates a [WarStrategyScreen] instance.
  const WarStrategyScreen({super.key});

  @override
  State<WarStrategyScreen> createState() => _WarStrategyScreenState();
}

class _WarStrategyScreenState extends State<WarStrategyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _battleController;

  final List<BattleScenario> _scenarios = [
    BattleScenario(
      name: 'Battle of Marathon',
      year: '490 BCE',
      description:
          'Persian invasion force lands at Marathon. Athenians are outnumbered.',
      playerSide: 'Athenians',
      enemySide: 'Persians',
      enemyTactic: Tactic.charge, // Persians relied on volume/arrows
      optimalTactic:
          Tactic.flank, // Historically, Miltiades strengthened flanks
    ),
    BattleScenario(
      name: 'Battle of Cannae',
      year: '216 BCE',
      description: 'Hannibal faces a massive Roman army.',
      playerSide: 'Carthage (Hannibal)',
      enemySide: 'Romans',
      enemyTactic: Tactic.charge, // Romans charged the center
      optimalTactic: Tactic.flank, // Hannibal\'s double envelopment
    ),
    BattleScenario(
      name: 'Battle of Hastings',
      year: '1066 CE',
      description: 'William the Conqueror attacks the Saxon shield wall.',
      playerSide: 'Normans',
      enemySide: 'Saxons',
      enemyTactic: Tactic.defense, // Saxons held the hill
      optimalTactic: Tactic.flank, // Feigned retreat (flanking/luring)
    ),
  ];

  BattleScenario? _selectedScenario;
  Tactic? _selectedTactic;
  bool _isBattling = false;
  String? _battleResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('War Strategy Sim', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        leading: _selectedScenario != null
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () {
                  _battleController.stop();
                  setState(() {
                    _selectedScenario = null;
                    _selectedTactic = null;
                    _isBattling = false;
                    _battleResult = null;
                  });
                })
            : null,
      ),
      body: LiquidBackground(
        child: _selectedScenario == null
            ? _buildScenarioSelector()
            : _buildBattleRoom(),
      ),
    );
  }

  @override
  void dispose() {
    _battleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _battleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // 5 second battle
    );
    _battleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _resolveBattle();
      }
    });
  }

  Widget _buildBattleRoom() {
    return Column(
      children: [
        // Battle View (Top)
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: GlassContainer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Terrain Background
                    Container(color: Colors.green[900]),

                    // Battle Visualization
                    AnimatedBuilder(
                      animation: _battleController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: BattlePainter(
                            progress: _battleController.value,
                            playerTactic: _selectedTactic ??
                                Tactic.charge, // Default for preview
                            enemyTactic: _selectedScenario!.enemyTactic,
                            scenario: _selectedScenario!,
                          ),
                        );
                      },
                    ),

                    if (_battleResult != null)
                      Center(
                        child: Text(
                          _battleResult!,
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _battleResult == 'VICTORY'
                                ? Colors.amber
                                : Colors.red,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Controls (Bottom)
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Command: ${_selectedScenario!.playerSide}',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Enemy: ${_selectedScenario!.enemySide}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Tactic:',
                  style:
                      GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTacticBtn(
                        Tactic.charge, 'Direct Charge', LucideIcons.moveUp),
                    const SizedBox(width: 8),
                    _buildTacticBtn(
                        Tactic.defense, 'Defensive', LucideIcons.shield),
                    const SizedBox(width: 8),
                    _buildTacticBtn(Tactic.flank, 'Flank', LucideIcons.split),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isBattling ? null : _startBattle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(_isBattling
                      ? 'BATTLE IN PROGRESS...'
                      : 'COMMENCE BATTLE'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioSelector() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
      itemCount: _scenarios.length,
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              child: const Icon(LucideIcons.swords, color: Colors.redAccent),
            ),
            title: Text(scenario.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${scenario.year}\n${scenario.description}',
                style: const TextStyle(color: Colors.white70)),
            trailing:
                const Icon(LucideIcons.chevronRight, color: Colors.white54),
            onTap: () => setState(() => _selectedScenario = scenario),
          ),
        );
      },
    );
  }

  Widget _buildTacticBtn(Tactic tactic, String label, IconData icon) {
    final isSelected = _selectedTactic == tactic;
    return Expanded(
      child: GestureDetector(
        onTap:
            _isBattling ? null : () => setState(() => _selectedTactic = tactic),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected ? Colors.amber : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.black : Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resolveBattle() {
    bool victory = false;
    String message = '';

    // Simple RPS Logic or specialized logic
    if (_selectedTactic == _selectedScenario!.optimalTactic) {
      victory = true;
      message = 'Victory! Your strategy outmaneuvered the enemy.';
    } else if (_selectedTactic == _selectedScenario!.enemyTactic) {
      // Tie/Stalemate usually bad for underdog
      victory = false;
      message = 'Stalemate. The enemy superiority wore you down.';
    } else {
      victory = false;
      message = 'Defeat. Your troops were countered effectively.';
    }

    setState(() {
      _isBattling = false;
      _battleResult = victory ? 'VICTORY' : 'DEFEAT';
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(victory ? 'GLORIOUS VICTORY' : 'CRUSHING DEFEAT',
            style: TextStyle(color: victory ? Colors.green : Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _startBattle() {
    if (_selectedScenario == null || _selectedTactic == null) return;
    setState(() {
      _isBattling = true;
      _battleResult = null;
    });
    _battleController.forward(from: 0.0);
  }
}
