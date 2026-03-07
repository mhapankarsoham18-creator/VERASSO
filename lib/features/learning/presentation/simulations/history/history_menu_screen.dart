import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'historical_atlas_screen.dart';
import 'civilizations_screen.dart';
import 'war_strategy_screen.dart';
import 'timeline_reconstructor_screen.dart';

/// Entry point for historical simulations and archaeological reconstructions.
class HistoryMenuScreen extends StatelessWidget {
  /// Creates a [HistoryMenuScreen] instance.
  const HistoryMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('History Labs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          children: [
            _buildActionCard(
              context,
              title: 'Historical Atlas',
              subtitle: 'Interactive Global Timeline',
              icon: LucideIcons.map,
              color: Colors.brown,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoricalAtlasScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Ancient Civilizations',
              subtitle: 'Explore lost cultures',
              icon: LucideIcons.landmark,
              color: Colors.amber,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CivilizationsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'War Strategy',
              subtitle: 'Historical Battle Simulations',
              icon: LucideIcons.sword,
              color: Colors.redAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WarStrategyScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Timeline Reconstructor',
              subtitle: 'Archaeological Puzzle',
              icon: LucideIcons.hourglass,
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimelineReconstructorScreen()),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
