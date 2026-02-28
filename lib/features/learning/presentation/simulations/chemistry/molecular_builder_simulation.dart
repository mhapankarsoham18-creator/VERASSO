import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A simulation for building molecules by dragging and dropping atoms into a builder area.
class MolecularBuilderSimulation extends StatefulWidget {
  /// Creates a [MolecularBuilderSimulation] instance.
  const MolecularBuilderSimulation({super.key});

  @override
  State<MolecularBuilderSimulation> createState() =>
      _MolecularBuilderSimulationState();
}

class _MolecularBuilderSimulationState
    extends State<MolecularBuilderSimulation> {
  // State
  final List<String> _atoms = [];
  String _result = "Empty";
  Color _resultColor = Colors.white54;
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Molecular Builder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _clear, icon: const Icon(LucideIcons.refreshCw))
        ],
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Visualization Area with DragTarget
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DragTarget<String>(
                      onWillAcceptWithDetails: (data) {
                        setState(() => _isDraggingOver = true);
                        return _atoms.length < 5;
                      },
                      onLeave: (data) {
                        setState(() => _isDraggingOver = false);
                      },
                      onAcceptWithDetails: (details) {
                        setState(() => _isDraggingOver = false);
                        _addAtom(details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _isDraggingOver
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isDraggingOver
                                  ? Colors.cyanAccent
                                  : Colors.white24,
                              width: _isDraggingOver ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: _atoms.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.touch_app,
                                        color: Colors.white30,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isDraggingOver
                                            ? 'Drop atom here!'
                                            : 'Drag atoms here to build molecules',
                                        style: const TextStyle(
                                            color: Colors.white30),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: _atoms
                                        .map((a) => _buildAtomVisual(a))
                                        .toList(),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _result,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _resultColor),
                    ),
                  ],
                ),
              ),
            ),

            // Controls with Draggable Atoms
            Expanded(
              flex: 2,
              child: GlassContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Drag Atoms',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap or drag atoms into the builder area',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDraggableAtom('H', Colors.white, 'Hydrogen'),
                        _buildDraggableAtom('O', Colors.red, 'Oxygen'),
                        _buildDraggableAtom('C', Colors.grey, 'Carbon'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addAtom(String atom) {
    setState(() {
      if (_atoms.length < 5) {
        _atoms.add(atom);
        _checkMolecule();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tray is full! Clear to start over.')));
      }
    });
  }

  Widget _buildAtomButton(String symbol, Color color, String name,
      {bool isDragging = false}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isDragging
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5)
                  ]
                : [const BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Center(
            child: Text(
              symbol,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAtomVisual(String symbol) {
    Color color;
    switch (symbol) {
      case 'O':
        color = Colors.red;
        break;
      case 'C':
        color = Colors.grey;
        break;
      default:
        color = Colors.white;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      alignment: Alignment.center,
      child: Text(symbol,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildDraggableAtom(String symbol, Color color, String name) {
    return Draggable<String>(
      data: symbol,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: _buildAtomButton(symbol, color, name, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildAtomButton(symbol, color, name),
      ),
      child: GestureDetector(
        onTap: () => _addAtom(symbol),
        child: _buildAtomButton(symbol, color, name),
      ),
    );
  }

  void _checkMolecule() {
    // Sort atoms to ignore order
    final sorted = List<String>.from(_atoms)..sort();
    final composition = sorted.join();

    // Specific recipes
    if (composition == "HHO") {
      _result = "Water (H₂O)";
      _resultColor = Colors.blueAccent;
    } else if (composition == "COO") {
      _result = "Carbon Dioxide (CO₂)";
      _resultColor = Colors.greenAccent;
    } else if (composition == "HHHH") {
      _result = "Hydrogen Gas (2H₂)";
      _resultColor = Colors.redAccent;
    } else if (composition == "OO") {
      _result = "Oxygen Gas (O₂)";
      _resultColor = Colors.cyanAccent;
    } else if (composition == "CHHHH") {
      _result = "Methane (CH₄)";
      _resultColor = Colors.orangeAccent;
    } else {
      _result = "Unstable / Unknown";
      _resultColor = Colors.white54;
    }

    if (_result != "Unstable / Unknown" && _result != "Empty") {
      // Phase 2: Persist Simulation Result
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          Supabase.instance.client.from('user_simulation_results').insert({
            'user_id': userId,
            'sim_id': 'molecular_builder',
            'parameters': {'atoms': _atoms},
            'results': {'molecule': _result},
          }).then((_) => debugPrint('Molecular builder result saved'));
        }
      } catch (e) {
        debugPrint('Error persisting molecular builder result: $e');
      }
    }
  }

  void _clear() {
    setState(() {
      _atoms.clear();
      _result = "Empty";
      _resultColor = Colors.white54;
    });
  }
}
