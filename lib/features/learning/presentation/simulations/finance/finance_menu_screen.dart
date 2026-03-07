import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/learning/data/transaction_repository.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

/// Basic Finance Hub for tracking credits and transactions.
class FinanceMenuScreen extends ConsumerWidget {
  /// Creates a [FinanceMenuScreen] instance.
  const FinanceMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Finance Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: userId == null 
          ? const Center(child: Text('Please log in to see finance data'))
          : ListView(
            padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
            children: [
              _buildBalanceCard(ref, userId),
              const SizedBox(height: 24),
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTransactionList(ref, userId),
            ],
          ),
      ),
    );
  }

  Widget _buildBalanceCard(WidgetRef ref, String userId) {
    return FutureBuilder<double>(
      future: ref.read(transactionRepositoryProvider).getUserBalance(userId),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        return GlassContainer(
          padding: const EdgeInsets.all(24),
          color: Colors.amber.withValues(alpha: 0.1),
          child: Column(
            children: [
              const Text(
                'Available VER Credits',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '${balance.toStringAsFixed(2)} V',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(WidgetRef ref, String userId) {
    return FutureBuilder<List<Transaction>>(
      future: ref.read(transactionRepositoryProvider).getTransactionHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('No transactions found')),
          );
        }
        return Column(
          children: txs.map((tx) => _buildTxTile(tx)).toList(),
        );
      },
    );
  }

  Widget _buildTxTile(Transaction tx) {
    final isPositive = tx.type == TransactionType.reward || tx.type == TransactionType.deposit;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isPositive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.type.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    tx.createdAt.toString().split('.')[0],
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? "+" : "-"}${tx.amount} V',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
