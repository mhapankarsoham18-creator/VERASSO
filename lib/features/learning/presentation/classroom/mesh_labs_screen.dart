import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../settings/presentation/mesh_network_screen.dart';
import '../ar_builder/ar_circuit_builder_screen.dart';
import 'ar_lab_screen.dart';
import 'classroom_session_screen.dart';
import 'doubt_swarm_screen.dart';
import 'mesh_journal_screen.dart';
import 'relay_game_screen.dart';

/// A hub for accessing various offline-first mesh networking simulations and tools.
class MeshLabsScreen extends StatelessWidget {
  /// Creates a [MeshLabsScreen] instance.
  const MeshLabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Mesh Labs (Offline)"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MeshNetworkScreen()));
            },
          ),
        ],
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Experience advanced learning without internet using local Bluetooth Mesh.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _MeshFeatureCard(
                title: "Classroom Mode",
                subtitle: "Join offline classes & participate in polls",
                icon: LucideIcons.presentation,
                color: Colors.blueAccent,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClassroomSessionScreen())),
              ).animate().fadeIn(delay: 100.ms).slideX(),
              const SizedBox(height: 16),
              _MeshFeatureCard(
                title: "Doubt Swarm",
                subtitle: "Route tricky questions to nearby experts",
                icon: LucideIcons.helpCircle,
                color: Colors.orangeAccent,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DoubtSwarmScreen())),
              ).animate().fadeIn(delay: 200.ms).slideX(),
              const SizedBox(height: 16),
              _MeshFeatureCard(
                title: "AR Shared Lab",
                subtitle: "Collaborative interactive simulations",
                icon: LucideIcons.box,
                color: Colors.purpleAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ArLabScreen())),
              ).animate().fadeIn(delay: 300.ms).slideX(),
              const SizedBox(height: 16),
              _MeshFeatureCard(
                title: "Mesh Journal",
                subtitle: "Collaborative offline note taking",
                icon: LucideIcons.bookOpen,
                color: Colors.greenAccent,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MeshJournalScreen())),
              ).animate().fadeIn(delay: 400.ms).slideX(),
              const SizedBox(height: 16),
              _MeshFeatureCard(
                title: "Knowledge Relay",
                subtitle: "Gamified knowledge sharing chain",
                icon: LucideIcons.zap,
                color: Colors.amberAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RelayGameScreen())),
              ).animate().fadeIn(delay: 500.ms).slideX(),
              const SizedBox(height: 16),
              _MeshFeatureCard(
                title: "AR Circuit Builder",
                subtitle: "Build circuits with hand gestures in AR",
                icon: LucideIcons.cpu,
                color: Colors.cyanAccent,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ArCircuitBuilderScreen())),
              ).animate().fadeIn(delay: 600.ms).slideX(),
              const SizedBox(height: 32),
              const Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.wifiOff, color: Colors.white24, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "All features work 100% offline",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
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
}

class _MeshFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MeshFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
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
