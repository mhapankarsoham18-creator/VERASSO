import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/features/learning/data/transaction_repository.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';

/// Provider for the user's current wallet balance.
final walletBalanceProvider = FutureProvider<double>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null) return 0.0;

  final repository = ref.read(transactionRepositoryProvider);
  return repository.getUserBalance(profile.id);
});
