import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'biology/biology_menu_screen.dart';
import 'chemistry/chemistry_menu_screen.dart';
import 'physics/physics_menu_screen.dart';

/// A screen that serves as the main entry point for different categories of interactive simulations.
class SimulationsMenuScreen extends StatelessWidget {
  /// Creates a [SimulationsMenuScreen] instance.
  const SimulationsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Interactive Simulations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: ListView(
          padding:
              const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
          children: [
            _buildCategoryCard(
              context,
              title: 'Physics',
              description: 'Explore mechanics, waves, and forces.',
              icon: LucideIcons.atom, // Physics related icon
              color: Colors.cyan,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PhysicsMenuScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCategoryCard(
              context,
              title: 'Chemistry',
              description: 'Bonding, reactions, and periodic table.',
              icon: LucideIcons.flaskConical,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ChemistryMenuScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCategoryCard(
              context,
              title: 'Biology',
              description: 'Cells, genetics, and life systems.',
              icon: LucideIcons.dna,
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BiologyMenuScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
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
