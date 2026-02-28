import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enterprise_model.dart';

/// Provider for the [EnterpriseSyncRepository] instance.
final enterpriseSyncProvider =
    NotifierProvider<EnterpriseSyncRepository, List<IdentityProof>>(
      EnterpriseSyncRepository.new,
    );

/// Repository responsible for syncing and verifying enterprise identity proofs.
class EnterpriseSyncRepository extends Notifier<List<IdentityProof>> {
  @override
  List<IdentityProof> build() {
    return [
      const IdentityProof(
        id: 'cert_1',
        certificateName: 'Junior Python Architect',
        issuingAuthority: 'Verasso Academic',
        isVerified: true,
        proofHash: '0xabc123...',
      ),
    ];
  }

  /// Triggers a synchronization process with the enterprise corporate portal.
  void syncWithEnterprise() async {
    // Simulate API call to corporate portal
    await Future.delayed(const Duration(seconds: 2));
    // In real app, send results to Verasso Enterprise Mesh
  }

  /// Verifies a specific [IdentityProof] by its [id].
  void verifyProof(String id) {
    state = [
      for (final p in state)
        if (p.id == id)
          IdentityProof(
            id: p.id,
            certificateName: p.certificateName,
            issuingAuthority: p.issuingAuthority,
            isVerified: true,
            proofHash: p.proofHash,
          )
        else
          p,
    ];
  }
}
