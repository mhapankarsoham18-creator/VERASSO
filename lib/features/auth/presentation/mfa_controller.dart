import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/auth_repository.dart';
import '../domain/mfa_models.dart';

/// Future provider that fetches the list of enrolled MFA factors for the current user.
final enrolledFactorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.listFactors();
});

/// Provider for the [MFAController] which handles MFA enrollment and unenrollment.
final mfaControllerProvider =
    StateNotifierProvider<MFAController, AsyncValue<void>>((ref) {
  return MFAController(ref.watch(authRepositoryProvider));
});

/// Controller that manages the state and actions for multi-factor authentication setup.
class MFAController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;

  /// Creates an [MFAController].
  MFAController(this._repo) : super(const AsyncData(null));

  /// Starts the MFA enrollment process.
  Future<MfaEnrollment?> enroll() async {
    state = const AsyncLoading();
    final response = await _repo.enrollMFA();
    state = const AsyncData(null);
    return response;
  }

  /// Unenrolls the specified [factorId] from the user's account.
  Future<void> unenroll(String factorId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.unenrollMFA(factorId: factorId));
  }

  /// Verifies a challenge and enables the MFA [factorId] with the provided [code].
  Future<void> verifyAndEnable(String factorId, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.challengeAndVerify(
          factorId: factorId,
          code: code,
        ));
  }
}
