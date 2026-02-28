import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A widget that displays a science simulation progress card for a specific [subject].
class ScienceSimulationWidget extends StatelessWidget {
  /// The academic subject being simulated (e.g., 'Chemistry', 'Physics').
  final String subject;

  /// Current progress of the simulation from 0.0 to 1.0.
  final double progress;

  /// Creates a [ScienceSimulationWidget] instance.
  const ScienceSimulationWidget({
    super.key,
    required this.subject,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getSubjectColor().withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                _getSubjectIcon(),
                size: 80,
                color: _getSubjectColor(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$subject SIMULATION',
                style: TextStyle(
                  color: _getSubjectColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Python logic controlling simulation parameters...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      color: _getSubjectColor(),
                      minHeight: 8,
                    ).animate().shimmer(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: _getSubjectColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor() {
    switch (subject.toLowerCase()) {
      case 'chemistry':
        return Colors.greenAccent;
      case 'physics':
        return Colors.blueAccent;
      case 'history':
        return Colors.amberAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  IconData _getSubjectIcon() {
    switch (subject.toLowerCase()) {
      case 'chemistry':
        return Icons.science;
      case 'physics':
        return Icons.speed;
      case 'history':
        return Icons.history_edu;
      default:
        return Icons.school;
    }
  }
}
