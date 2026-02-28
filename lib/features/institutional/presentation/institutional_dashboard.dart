import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A screen for institutions to view aggregate mastery data from local peers.
class InstitutionalDashboard extends ConsumerWidget {
  /// Creates an [InstitutionalDashboard] instance.
  const InstitutionalDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Institutional Mastery')),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const GlassContainer(
              child: Column(
                children: [
                  Text('Local Network Analytics',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCard(label: 'Active Peers', value: '12'),
                      _StatCard(label: 'Avg Mastery', value: '78%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Peer Proficiency Breakout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _PeerListTile(name: 'User_442', skill: 'Pharmacology', level: 0.92),
            _PeerListTile(name: 'User_219', skill: 'AR Layout', level: 0.85),
            _PeerListTile(
                name: 'User_901', skill: 'Doubt Resolution', level: 0.64),
          ],
        ),
      ),
    );
  }
}

class _PeerListTile extends StatelessWidget {
  final String name;
  final String skill;
  final double level;
  const _PeerListTile(
      {required this.name, required this.skill, required this.level});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(LucideIcons.user)),
        title: Text(name),
        subtitle: Text(skill),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('${(level * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
