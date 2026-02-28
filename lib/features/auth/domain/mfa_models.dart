/// Domain model representing an MFA challenge response.
class MfaChallenge {
  /// Unique identifier for the challenge.
  final String id;

  /// Creates an [MfaChallenge] instance.
  MfaChallenge({required this.id});
}

/// Domain model representing an MFA enrollment response.
class MfaEnrollment {
  /// Unique identifier for the enrollment.
  final String id;

  /// The type of MFA factor (e.g., 'totp').
  final String type;

  /// The secret key for TOTP enrollment.
  final String? totpSecret;

  /// The URI for TOTP enrollment (e.g., for QR codes).
  final String? totpUri;

  /// Creates an [MfaEnrollment] instance.
  MfaEnrollment({
    required this.id,
    required this.type,
    this.totpSecret,
    this.totpUri,
  });
}
