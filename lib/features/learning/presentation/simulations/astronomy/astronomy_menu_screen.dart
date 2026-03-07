import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'solar_system_simulation.dart';
import 'stargazing_feed_screen.dart';
import 'create_stargazing_log_screen.dart';

/// Screen displaying the directory of Astronomy simulations and tools.
class AstronomyMenuScreen extends StatelessWidget {
  /// Creates an [AstronomyMenuScreen] instance.
  const AstronomyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Astronomy Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          children: [
            _buildActionCard(
              context,
              title: 'Solar System',
              subtitle: 'Interactive 3D Simulation',
              icon: LucideIcons.sun,
              color: Colors.orangeAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SolarSystemSimulation(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Stargazing Feed',
              subtitle: 'Community Observations',
              icon: LucideIcons.sparkles,
              color: Colors.purpleAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StargazingFeedScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Create Log',
              subtitle: 'Record your observation',
              icon: LucideIcons.pencil,
              color: Colors.blueAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateStargazingLogScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
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
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
