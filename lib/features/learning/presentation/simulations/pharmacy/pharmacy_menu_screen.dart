import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'ar_drug_viewer_screen.dart';
import 'enzyme_kinetics_screen.dart';
import 'formulation_lab_screen.dart';
import 'pkpd_simulator_screen.dart';

/// A screen that displays a menu of available pharmacy and pharmacology simulations.
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
            const GlassContainer(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pharmacology Command Center',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explore pharmaceutical sciences through high-fidelity AR simulations and interactive labs.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _MenuCard(
              title: 'AR Molecule Viewer',
              subtitle: 'Visualize drug structures in 3D AR',
              icon: LucideIcons.box,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ARDrugViewerScreen(
                      drugName: 'Paracetamol',
                      modelPath:
                          'assets/models/paracetamol.glb', // Local asset required or remote URL
                      description:
                          'N-acetyl-p-aminophenol, a widely used analgesic and antipyretic agent.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuCard(
              title: 'Drug-Drug Interactions',
              subtitle: 'Simulate biochemical synergism',
              icon: LucideIcons.activity,
              color: Colors.greenAccent,
              onTap: () {
                // Navigate to Interaction Simulator
              },
            ),
            const SizedBox(height: 16),
            _MenuCard(
              title: 'Virtual Formulation Lab',
              subtitle: 'Drag-and-drop excipient mixer',
              icon: LucideIcons.beaker,
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FormulationLabScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuCard(
              title: 'Clinical Pharmacology',
              subtitle: 'PK/PD Math Simulator',
              icon: LucideIcons.stethoscope,
              color: Colors.purpleAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PKPDSimulatorScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuCard(
              title: 'Molecular Binding',
              subtitle: 'Enzyme-Substrate Kinetics',
              icon: LucideIcons.zap,
              color: Colors.amber,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EnzymeKineticsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
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
        padding: const EdgeInsets.all(20),
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
