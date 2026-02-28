import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'ar_temple_reconstruction_screen.dart';
import 'historical_atlas_screen.dart';
import 'timeline_reconstructor_screen.dart';

/// A screen that displays a menu of available history simulations and heritage experiences.
class HistoryMenuScreen extends StatelessWidget {
  /// Creates a [HistoryMenuScreen] instance.
  const HistoryMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('History & Heritage'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
          children: [
            _HistoryCard(
              title: 'Historical Atlas',
              subtitle: 'Timelines & trade routes across regions',
              icon: LucideIcons.map,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HistoricalAtlasScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _HistoryCard(
              title: 'Timeline Reconstructor',
              subtitle: 'Reorder scrambled historical events',
              icon: LucideIcons.calendar,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TimelineReconstructorScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _HistoryCard(
              title: 'AR Temple Reconstruction',
              subtitle: 'Visualize ancient architecture in 3D AR',
              icon: LucideIcons.landmark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ARTempleReconstructionScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _HistoryCard(
              title: 'AI Historical Interviews',
              subtitle: 'Talk to legacy figures (Coming Soon)',
              icon: LucideIcons.messageSquare,
              onTap: () {},
              isEnabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.amber, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
