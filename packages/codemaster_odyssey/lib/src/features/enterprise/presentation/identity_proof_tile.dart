import 'package:flutter/material.dart';

import '../domain/enterprise_model.dart';

/// A list tile widget that displays an [IdentityProof] and provides a verify action.
class IdentityProofTile extends StatelessWidget {
  /// The identity proof to display.
  final IdentityProof proof;

  /// Callback triggered when the 'VERIFY' button is pressed.
  final VoidCallback onVerify;

  /// Creates an [IdentityProofTile] widget.
  const IdentityProofTile({
    super.key,
    required this.proof,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          proof.isVerified ? Icons.verified_user : Icons.gpp_maybe,
          color: proof.isVerified ? Colors.cyanAccent : Colors.amberAccent,
        ),
        title: Text(
          proof.certificateName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              proof.issuingAuthority,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Text(
              'Proof: ${proof.proofHash}',
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        trailing: proof.isVerified
            ? const Icon(Icons.check_circle, color: Colors.greenAccent)
            : ElevatedButton(
                onPressed: onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                  foregroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'VERIFY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}
