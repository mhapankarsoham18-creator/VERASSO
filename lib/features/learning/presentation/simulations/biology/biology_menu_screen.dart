import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'cell_structure_simulation.dart';
import 'synapse_sim_screen.dart';

/// A screen that displays a menu of available biology simulations, such as cell structure and synapses.
class BiologyMenuScreen extends StatelessWidget {
  /// Creates a [BiologyMenuScreen] instance.
  const BiologyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Biology Lab'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          children: [
            _buildSimItem(
              context,
              title: "Cell Structure",
              description: "Interactive Animal Cell model.",
              icon: LucideIcons.atom, // Best fit for cell/nucleus
              color: Colors.green,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CellStructureSimulation())),
            ),
            const SizedBox(height: 16),
            _buildSimItem(
              context,
              title: "DNA Interactive",
              description: "Double helix structure.",
              icon: LucideIcons.dna,
              color: Colors.pinkAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming Soon!')));
              },
            ),
            const SizedBox(height: 16),
            _buildSimItem(
              context,
              title: "Synaptic Transmission",
              description: "Neuron firing & receptors.",
              icon: LucideIcons.zap,
              color: Colors.amber,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SynapseSimScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimItem(BuildContext context,
      {required String title,
      required String description,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.5))),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
