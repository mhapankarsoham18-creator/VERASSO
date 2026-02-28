/// Represents a cryptographic identity proof or certificate for corporate/enterprise validation.
class IdentityProof {
  /// Unique identifier for the identity proof.
  final String id;

  /// Human-readable name of the certificate.
  final String certificateName;

  /// The organization that issued the certificate.
  final String issuingAuthority;

  /// Whether the certificate has been verified by the Verasso Enterprise Mesh.
  final bool isVerified;

  /// Hex representation of the simulated Zero-Knowledge proof hash.
  final String proofHash;

  /// Creates an [IdentityProof] instance.
  const IdentityProof({
    required this.id,
    required this.certificateName,
    required this.issuingAuthority,
    this.isVerified = false,
    required this.proofHash,
  });
}
