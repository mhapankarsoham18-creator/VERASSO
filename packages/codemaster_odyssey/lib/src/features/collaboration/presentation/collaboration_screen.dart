import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'classroom_analytics_dashboard.dart';
import 'mentorship_dashboard.dart';

/// Main screen for the Collaboration feature, hosting dashboards for mentorship and analytics.
class CollaborationScreen extends ConsumerWidget {
  /// Creates a [CollaborationScreen] widget.
  const CollaborationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'COLLABORATION HUB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MentorshipDashboard(),
          SizedBox(height: 24),
          ClassroomAnalyticsDashboard(),
          SizedBox(height: 24),
          _MentorshipTipCard(),
        ],
      ),
    );
  }
}

class _MentorshipTipCard extends StatelessWidget {
  const _MentorshipTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withValues(alpha: 0.1),
            Colors.purpleAccent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.amberAccent),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Helping others earns you the "Sage" title and unique cosmetic rewards.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
