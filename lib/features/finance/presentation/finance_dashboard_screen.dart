import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/finance/data/finance_repository.dart';
import 'package:verasso/features/finance/data/transaction_model.dart';
import 'package:verasso/features/finance/presentation/analytics_screen.dart';

/// Entry screen for a user’s personal finance hub.
///
/// Shows aggregated net worth, quick stats, and recent transaction history,
/// and links through to the detailed [AnalyticsScreen].
class FinanceDashboardScreen extends ConsumerStatefulWidget {
  /// Creates a [FinanceDashboardScreen] instance.
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends ConsumerState<FinanceDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Financial Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pieChart),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNetWorthCard(userId),
              const SizedBox(height: 24),
              const Text('Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTransactionHistory(userId),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the glassmorphic card that displays the user's net earnings and
  /// a couple of derived quick stats.
  Widget _buildNetWorthCard(String userId) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(financeRepositoryProvider).getFinancialStats(userId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'income': 0.0, 'expense': 0.0};
        final income = stats['income'] ?? 0.0;
        final expense = stats['expense'] ?? 0.0;
        final netWorth = income - expense;

        return Semantics(
          label: 'Financial overview',
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('Total Net Earnings',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Total net earnings: \$${netWorth.toStringAsFixed(2)}',
                  child: Text(
                    '\$${netWorth.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Semantics(
                      label: 'Total income: \$${income.toStringAsFixed(2)}',
                      child: _buildQuickStat(
                          LucideIcons.arrowUpRight,
                          ' Income',
                          '\$${income.toStringAsFixed(2)}',
                          Colors.green),
                    ),
                    Semantics(
                      label: 'Total expenses: \$${expense.toStringAsFixed(2)}',
                      child: _buildQuickStat(
                          LucideIcons.arrowDownLeft,
                          ' Expenses',
                          '\$${expense.toStringAsFixed(2)}',
                          Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Small label/value pair used for summary stats within the dashboard.
  Widget _buildQuickStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            Text(label, style: const TextStyle(color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Renders a list of recent [Transaction]s for the given [userId].
  ///
  /// Falls back to a friendly empty state when no transactions exist.
  Widget _buildTransactionHistory(String userId) {
    return FutureBuilder<List<Transaction>>(
      future: ref.read(financeRepositoryProvider).getTransactionHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No transactions yet.',
              style: TextStyle(color: Colors.white54));
        }

        return Semantics(
          label: 'Transaction history list',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = snapshot.data![index];
              final txText =
                  '${tx.isCredit ? 'Credit' : 'Debit'} transaction: ${tx.description ?? tx.category}, \$${tx.amount.toStringAsFixed(2)} on ${DateFormat.yMMMd().format(tx.createdAt)}';
              return Semantics(
                label: txText,
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (tx.isCredit ? Colors.green : Colors.red)
                              .withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tx.isCredit
                              ? LucideIcons.arrowDownLeft
                              : LucideIcons.arrowUpRight,
                          color: tx.isCredit
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.description ?? tx.category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(DateFormat.yMMMd().format(tx.createdAt),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.isCredit ? '+' : '-'} \$${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              tx.isCredit ? Colors.greenAccent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
