import 'dart:async';

import 'mfa_models.dart';

/// Result of an authentication operation.
class AuthResult {
  /// The user object, if sign-in/sign-up was successful.
  final DomainAuthUser? user;

  /// The session object, if sign-in/sign-up was successful.
  final DomainAuthSession? session;

  /// Creates an [AuthResult] instance.
  AuthResult({this.user, this.session});
}

/// Interface for authentication services.
abstract class AuthService {
  /// Stream of authentication state changes.
  Stream<DomainAuthUser?> get authStateChanges;

  /// The currently authenticated user, if any.
  DomainAuthUser? get currentUser;

  // --- MFA Methods ---

  /// Verifies a challenge with the provided [code] for the given [factorId].
  Future<void> challengeAndVerify({
    required String factorId,
    required String code,
  });

  /// Challenges an MFA factor with the provided [factorId].
  Future<MfaChallenge> challengeMFA({required String factorId});

  /// Deletes the current user's account and all associated personal data.
  Future<void> deleteAccount();

  /// Enrolls the user in a new MFA factor.
  Future<MfaEnrollment?> enrollMFA();

  /// Lists all MFA factors enrolled for the user.
  Future<List<dynamic>> listFactors();

  /// Initiates a password reset flow.
  Future<void> resetPasswordForEmail({required String email});

  // --- OTP Methods ---

  /// Authenticates a user using their email and password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Authenticates a user using their email and an OTP.
  Future<void> signInWithOtp({required String email});

  /// Signs out the current user.
  Future<void> signOut();

  /// Creates a new user account.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    Map<String, dynamic>? data,
  });

  /// Unenrolls the user from an MFA factor.
  Future<void> unenrollMFA({required String factorId});

  /// Updates the current user's password.
  Future<void> updateUserPassword({required String password});

  /// Verifies an MFA challenge and returns the resulting session.
  Future<AuthResult?> verifyMFA({
    required String factorId,
    required String challengeId,
    required String code,
  });

  /// Verifies an OTP and returns the resulting session.
  Future<AuthResult?> verifyOtp({
    required String token,
    required dynamic type,
    String? email,
  });
}

/// Domain representation of an MFA factor.
class DomainAuthFactor {
  /// The unique ID of the factor.
  final String id;

  /// The status of the factor.
  final String status;

  /// The type of the factor (e.g. 'totp').
  final String type;

  /// Creates a [DomainAuthFactor] instance.
  DomainAuthFactor({
    required this.id,
    required this.status,
    required this.type,
  });
}

/// Domain representation of an active session.
class DomainAuthSession {
  /// The access token for the session.
  final String accessToken;

  /// The refresh token for the session, if any.
  final String? refreshToken;

  /// The user object associated with the session.
  final DomainAuthUser? user;

  /// Creates a [DomainAuthSession] instance.
  DomainAuthSession({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });
}

/// Domain representation of an authenticated user.
class DomainAuthUser {
  /// The unique ID of the user.
  final String id;

  /// The email address of the user, if any.
  final String? email;

  /// Metadata associated with the user.
  final Map<String, dynamic> userMetadata;

  /// The timestamp when the user's email was confirmed, if any.
  final String? emailConfirmedAt;

  /// List of MFA factors enrolled for this user.
  final List<DomainAuthFactor> factors;

  /// Creates a [DomainAuthUser] instance.
  DomainAuthUser({
    required this.id,
    this.email,
    this.userMetadata = const {},
    this.emailConfirmedAt,
    this.factors = const [],
  });
}
