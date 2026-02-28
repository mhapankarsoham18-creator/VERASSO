import 'package:flutter/material.dart';

/// Dashboard widget that displays high-level classroom performance metrics.
class ClassroomAnalyticsDashboard extends StatelessWidget {
  /// Creates a [ClassroomAnalyticsDashboard] widget.
  const ClassroomAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLASSROOM ANALYTICS',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: 'Avg. Lesson Progress',
            value: '68%',
            color: Colors.blueAccent,
          ),
          _StatRow(
            label: 'Active Apprentices',
            value: '24',
            color: Colors.greenAccent,
          ),
          _StatRow(
            label: 'Hardest Realm',
            value: 'Logic Labyrinth',
            color: Colors.redAccent,
          ),
          const Spacer(),
          const Center(
            child: Icon(Icons.bar_chart, color: Colors.white10, size: 60),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
