/// Financial Forecasting AI for the Accounting Simulator (Simplified Projection Model)
class ForecastingAiService {
  /// Calculates the runway in months based on current cash and expenses.
  double calculateBurnRate(double monthlyExpenses, double currentCash) {
    if (monthlyExpenses <= 0) return double.infinity;
    return currentCash / monthlyExpenses;
  }

  /// Predict future balance sheet based on historical ledger entries
  Future<Map<String, double>> forecastNextQuarter(
      Map<String, double> currentAssets,
      List<double> historicalMonthlyBalances) async {
    // Linear Regression Extrapolation
    double trend = 1.0;
    if (historicalMonthlyBalances.length >= 2) {
      final first = historicalMonthlyBalances.first;
      final last = historicalMonthlyBalances.last;
      trend = last / (first > 0 ? first : 1.0);
    }

    return currentAssets.map((key, value) {
      // Projected value influenced by historical trend
      final projection = value * trend;
      return MapEntry(key, projection);
    });
  }
}
