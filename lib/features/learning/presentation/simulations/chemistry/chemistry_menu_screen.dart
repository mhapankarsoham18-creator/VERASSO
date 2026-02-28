import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'molecular_builder_simulation.dart';
import 'periodic_table_screen.dart';
import 'titration_lab_screen.dart';

/// A screen that displays a menu of available chemistry simulations, for building molecules and exploring the periodic table.
class ChemistryMenuScreen extends StatelessWidget {
  /// Creates a [ChemistryMenuScreen] instance.
  const ChemistryMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Chemistry Lab'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          children: [
            _buildSimItem(
              context,
              title: "Molecular Builder",
              description: "Construct molecules from atoms.",
              icon: LucideIcons.flaskConical,
              color: Colors.purpleAccent,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MolecularBuilderSimulation())),
            ),
            const SizedBox(height: 16),
            _buildSimItem(
              context,
              title: "Periodic Table",
              description: "Explore the elements.",
              icon: LucideIcons.table,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PeriodicTableScreen())),
            ),
            const SizedBox(height: 16),
            _buildSimItem(
              context,
              title: "Titration Lab",
              description: "Precise acid-base simulations.",
              icon: LucideIcons.beaker,
              color: Colors.greenAccent,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TitrationLabScreen())),
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
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
