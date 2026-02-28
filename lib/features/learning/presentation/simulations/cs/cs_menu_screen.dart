import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../management/ar_boardroom_screen.dart';
import '../management/compliance_tracker_screen.dart';
import '../management/resolution_drafter_screen.dart';

/// A screen that displays a menu of available Computer Science and Management simulations.
class CSMenuScreen extends StatelessWidget {
  /// Creates a [CSMenuScreen] instance.
  const CSMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('CS & Management'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
          children: [
            _CSCard(
              title: 'AR Boardroom Simulation',
              subtitle: 'Practice board meetings and governance',
              icon: LucideIcons.users,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ARBoardroomScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _CSCard(
              title: 'Resolution Drafter',
              subtitle: 'Smart templates for board resolutions',
              icon: LucideIcons.fileText,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ResolutionDrafterScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _CSCard(
              title: 'Compliance Tracker',
              subtitle: 'ROC & SEBI filing simulation',
              icon: LucideIcons.checkSquare,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ComplianceTrackerScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card widget for displaying Computer Science simulation options in the menu.
class _CSCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CSCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.indigoAccent, size: 30),
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
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
