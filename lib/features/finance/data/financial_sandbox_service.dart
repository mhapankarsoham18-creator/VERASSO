import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [FinancialSandboxService] state notifier.
final financialSandboxProvider =
    StateNotifierProvider<FinancialSandboxService, FinancialState>((ref) {
  return FinancialSandboxService();
});

/// Service managing simulated sovereign financial transactions within the app sandbox.
class FinancialSandboxService extends StateNotifier<FinancialState> {
  /// Creates a [FinancialSandboxService] instance.
  FinancialSandboxService() : super(FinancialState());

  /// Adds funds to the sandbox wallet.
  Future<void> addFunds(double amount) async {
    state = state.copyWith(isProcessing: true);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(
      balance: state.balance + amount,
      transactionHistory: [
        ...state.transactionHistory,
        'Added \$$amount to wallet'
      ],
      isProcessing: false,
    );
  }

  /// Attempts to process a payment for a specific [amount].
  Future<bool> processPayment(double amount, String description) async {
    if (state.balance < amount) {
      AppLogger.warning(
          'FinancialSandbox: Insufficient funds for $description');
      return false;
    }

    state = state.copyWith(isProcessing: true);

    // Simulate payment gateway delay
    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(
      balance: state.balance - amount,
      transactionHistory: [
        ...state.transactionHistory,
        'Paid \$$amount for $description'
      ],
      isProcessing: false,
    );

    AppLogger.info(
        'FinancialSandbox: Successfully processed payment: $description (\$$amount)');
    return true;
  }
}

/// State model for the user's sovereign financial wallet.
class FinancialState {
  /// The current balance in the wallet.
  final double balance;

  /// The history of transactions performed in the sandbox.
  final List<String> transactionHistory;

  /// Whether a financial transaction is currently being processed.
  final bool isProcessing;

  /// Creates a [FinancialState] instance.
  FinancialState({
    this.balance = 500.0,
    this.transactionHistory = const [],
    this.isProcessing = false,
  });

  /// Creates a copy of this [FinancialState] with the given fields replaced.
  FinancialState copyWith({
    double? balance,
    List<String>? transactionHistory,
    bool? isProcessing,
  }) {
    return FinancialState(
      balance: balance ?? this.balance,
      transactionHistory: transactionHistory ?? this.transactionHistory,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
