import 'package:flutter/material.dart';

import 'certification_dashboard.dart';

/// Main screen for managing enterprise synchronization and identity proofs.
class EnterpriseSyncScreen extends StatelessWidget {
  /// Creates an [EnterpriseSyncScreen] widget.
  const EnterpriseSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ENTERPRISE SYNC CENTER',
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
          CertificationDashboard(),
          SizedBox(height: 24),
          _TrustScoreWidget(),
        ],
      ),
    );
  }
}

class _TrustScoreWidget extends StatelessWidget {
  const _TrustScoreWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
      ),
      child: const Column(
        children: [
          Text(
            'ZK-TRUST SCORE',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '921',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'HIGHLY RELIABLE APPRENTICE',
            style: TextStyle(color: Colors.greenAccent, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
