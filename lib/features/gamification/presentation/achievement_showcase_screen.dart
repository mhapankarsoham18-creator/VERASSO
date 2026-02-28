import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A screen that showcases a user's mastery certificates and academic milestones.
class AchievementShowcaseScreen extends StatelessWidget {
  /// Creates an [AchievementShowcaseScreen] instance.
  const AchievementShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mastery Certificates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Academic Legacy',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verified expertise and academic milestones.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildCertificateCard(
                      'Physics Mastery',
                      'Level 42 Quantum Mechanics',
                      LucideIcons.atom,
                      Colors.blueAccent,
                    ),
                    _buildCertificateCard(
                      'Financial Literacy',
                      'Certified Double-Entry Expert',
                      LucideIcons.trendingUp,
                      Colors.greenAccent,
                    ),
                    _buildCertificateCard(
                      'Mesh Architect',
                      'Distributed Network Specialist',
                      LucideIcons.network,
                      Colors.orangeAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateCard(
      String title, String subtitle, IconData icon, Color color) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const Icon(LucideIcons.award, color: Colors.yellowAccent),
        ],
      ),
    );
  }
}
