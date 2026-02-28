import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'ecosphere_comparison_screen.dart';
import 'interactive_globe_screen.dart';

/// A screen that displays a menu of available geography simulations, such as the interactive globe and plate tectonics.
class GeographyMenuScreen extends StatelessWidget {
  /// Creates a [GeographyMenuScreen] instance.
  const GeographyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Geography Lab'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
          children: [
            _SimCard(
              title: 'Interactive 3D Globe',
              subtitle: 'Earth orientation, layers & tectonic plates',
              icon: LucideIcons.globe,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const InteractiveGlobeScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _SimCard(
              title: 'Climate Patterns',
              subtitle: 'Atmospheric circulation & wind (Coming Soon)',
              icon: LucideIcons.cloud,
              onTap: () {},
              isEnabled: false,
            ),
            const SizedBox(height: 16),
            _SimCard(
              title: 'EcoSphere comparison',
              subtitle: 'Vegetation, Fauna & Biome data',
              icon: LucideIcons.leaf,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EcoSphereComparisonScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _SimCard({
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
              Icon(icon, color: Colors.blueAccent, size: 40),
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
