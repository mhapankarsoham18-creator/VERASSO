import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enterprise_repository.dart';
import 'identity_proof_tile.dart';

/// Dashboard widget for managing and viewing corporate certifications.
class CertificationDashboard extends ConsumerWidget {
  /// Creates a [CertificationDashboard] widget.
  const CertificationDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofs = ref.watch(enterpriseSyncProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CORPORATE CERTIFICATIONS',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        ...proofs.map(
          (proof) => IdentityProofTile(
            proof: proof,
            onVerify: () =>
                ref.read(enterpriseSyncProvider.notifier).verifyProof(proof.id),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              const Icon(Icons.cloud_sync, color: Colors.white24, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Verasso Enterprise Sync Active',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(enterpriseSyncProvider.notifier)
                    .syncWithEnterprise(),
                icon: const Icon(Icons.sync),
                label: const Text('SYNC NOW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
