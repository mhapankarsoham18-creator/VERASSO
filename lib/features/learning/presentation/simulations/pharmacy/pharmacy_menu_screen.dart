import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'formulation_lab_screen.dart';
import 'pkpd_simulator_screen.dart';
import 'enzyme_kinetics_screen.dart';

/// Entry point for Pharmacy and Pharmacology simulations.
class PharmacyMenuScreen extends StatelessWidget {
  /// Creates a [PharmacyMenuScreen] instance.
  const PharmacyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pharmacy Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          children: [
            _buildActionCard(
              context,
              title: 'Formulation Lab',
              subtitle: 'Compound your own medicine',
              icon: LucideIcons.beaker,
              color: Colors.redAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FormulationLabScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'PK/PD Simulator',
              subtitle: 'Drug Concentration over Time',
              icon: LucideIcons.trendingUp,
              color: Colors.orangeAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PKPDSimulatorScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Enzyme Kinetics',
              subtitle: 'Michaelis-Menten Simulation',
              icon: LucideIcons.dna,
              color: Colors.greenAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EnzymeKineticsScreen()),
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
