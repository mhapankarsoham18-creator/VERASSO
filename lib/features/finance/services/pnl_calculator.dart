/// A utility class for calculating realized and unrealized profit and loss (P&L),
/// as well as estimating capital gains tax.
class PnLCalculator {
  /// Calculate Realized P&L from a sell transaction
  static double calculateRealizedPnL({
    required double sellPrice,
    required double buyPrice,
    required double units,
  }) {
    return (sellPrice - buyPrice) * units;
  }

  /// Calculate Unrealized P&L for a single holding
  static Map<String, dynamic> calculateUnrealizedPnL({
    required double averagePrice,
    required double currentPrice,
    required double units,
  }) {
    final costBasis = averagePrice * units;
    final marketValue = currentPrice * units;
    final pnl = marketValue - costBasis;
    final pnlPercent = costBasis > 0 ? (pnl / costBasis) * 100 : 0.0;

    return {
      'marketValue': marketValue,
      'costBasis': costBasis,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
    };
  }

  /// Estimate Capital Gains Tax
  /// Short-term (held < 1yr) taxed as income
  /// Long-term (held > 1yr) taxed at lower rate (0%, 15%, 20%)
  static double estimateTax({
    required double gain,
    required double annualIncome,
    required bool isLongTerm,
    required String filingStatus, // 'single', 'married'
  }) {
    if (gain <= 0) return 0.0;

    if (!isLongTerm) {
      // Short-term: Taxed as ordinary income
      // Simplified bracket logic for 2024
      return gain * _getMarginalRate(annualIncome, filingStatus);
    } else {
      // Long-term capital gains rates
      return gain * _getLongTermRate(annualIncome, filingStatus);
    }
  }

  static double _getLongTermRate(double income, String status) {
    if (status == 'single') {
      if (income > 518900) return 0.20;
      if (income > 47025) return 0.15;
      return 0.0;
    } else {
      if (income > 583750) return 0.20;
      if (income > 94050) return 0.15;
      return 0.0;
    }
  }

  static double _getMarginalRate(double income, String status) {
    // Very simplified 2024 brackets
    if (status == 'single') {
      if (income > 609350) return 0.37;
      if (income > 243725) return 0.35;
      if (income > 191950) return 0.32;
      if (income > 100525) return 0.24;
      if (income > 47150) return 0.22;
      if (income > 11600) return 0.12;
      return 0.10;
    } else {
      // Married filing jointly
      if (income > 731200) return 0.37;
      if (income > 487450) return 0.35;
      if (income > 383900) return 0.32;
      if (income > 201050) return 0.24;
      if (income > 94300) return 0.22;
      if (income > 23200) return 0.12;
      return 0.10;
    }
  }
}
