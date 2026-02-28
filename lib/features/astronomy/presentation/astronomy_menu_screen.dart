import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/theme/app_colors.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../learning/presentation/simulations/astronomy/solar_system_simulation.dart';
import '../../learning/presentation/simulations/astronomy/stargazing_feed_screen.dart';
import '../../settings/presentation/theme_controller.dart';
import 'ar_stargazing_screen.dart';

/// Main menu screen for astronomy-related features and simulations.
class AstronomyMenuScreen extends ConsumerWidget {
  /// Creates an [AstronomyMenuScreen].
  const AstronomyMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cosmic Explorer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            // Parallax Stars Overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?auto=format&fit=crop&w=1500&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                )
                    .animate(
                        onPlay: (controller) => themeState.isPowerSaveMode
                            ? controller.stop()
                            : controller.repeat())
                    .moveY(begin: 0, end: -100, duration: 60.seconds),
              ),
            ),

            ListView(
              padding: const EdgeInsets.only(
                  top: 100, left: 16, right: 16, bottom: 20),
              children: [
                // AR Stargazing
                _buildMenuCard(
                  context,
                  title: 'AR Stargazing',
                  subtitle:
                      'Point your camera at the sky\nSee constellations & planets in real-time',
                  icon: LucideIcons.camera,
                  gradient: [AppColors.primary, AppColors.etherealCyan],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ArStargazingScreen())),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                // Community Logs
                _buildMenuCard(
                  context,
                  title: 'Stargazing Logs',
                  subtitle:
                      'Join the community\nShare and view universal sightings',
                  icon: LucideIcons.eye,
                  gradient: [Colors.purpleAccent, Colors.deepPurple],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StargazingFeedScreen())),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                // Solar System 3D
                _buildMenuCard(
                  context,
                  title: 'Solar System 3D',
                  subtitle:
                      'High-fidelity orrery\nInteractive planetary simulation',
                  icon: LucideIcons.globe,
                  gradient: [Colors.orangeAccent, Colors.redAccent],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SolarSystemSimulation())),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                // Mission Parameters Card
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.info,
                              size: 20, color: AppColors.etherealCyan),
                          SizedBox(width: 8),
                          Text('Mission Parameters',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem('📍', 'Precision GPS Lock'),
                      _buildInfoItem('📱', 'IMU Orientation Mapping'),
                      _buildInfoItem('🌌', 'Hyperspectral Overlay'),
                      _buildInfoItem('⭐', 'Dynamic Ephemeris Sync'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '💡 Operational Alert: Best used in dark areas away from light pollution',
                          style: TextStyle(
                              fontSize: 11, color: Colors.orangeAccent),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ).animate().shimmer(duration: 2.seconds, color: Colors.white24),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          trailing: const Icon(LucideIcons.chevronRight, size: 16),
        ),
      ),
    );
  }
}
