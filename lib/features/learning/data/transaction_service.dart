import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import 'transaction_repository.dart';

/// Provides access to the [TransactionService] used in the learning marketplace.
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionService(repo);
});

/// Domain service that coordinates course purchases and balance checks.
class TransactionService {
  final TransactionRepository _repository;

  /// Creates a [TransactionService] that wraps the given [TransactionRepository].
  TransactionService(this._repository);

  /// Attempts to process a course purchase for [userId] and [courseId].
  ///
  /// Returns `true` when the user has sufficient balance and the transaction
  /// is recorded successfully, otherwise returns `false`.
  Future<bool> processCoursePurchase(
      String userId, String courseId, double price) async {
    try {
      final balance = await _repository.getUserBalance(userId);

      if (balance < price) {
        AppLogger.warning(
            'TransactionService: Insufficient balance ($balance < $price)');
        return false;
      }

      final transaction = Transaction(
        id: '', // Supabase will generate
        userId: userId,
        targetId: courseId,
        type: TransactionType.purchase,
        amount: -price,
        createdAt: DateTime.now(),
        metadata: {'category': 'course_purchase'},
      );

      await _repository.recordTransaction(transaction);
      AppLogger.info(
          'TransactionService: Course $courseId purchased by $userId');
      return true;
    } catch (e) {
      AppLogger.error('TransactionService: Purchase error', error: e);
      return false;
    }
  }

  /// Records a raw transaction in the ledger.
  Future<void> recordTransaction(Transaction transaction) async {
    await _repository.recordTransaction(transaction);
  }
}
