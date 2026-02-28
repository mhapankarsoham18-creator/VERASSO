import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../profile/presentation/profile_controller.dart';
import '../data/wallet_provider.dart';

/// Wallet view showing a creator’s earnings balance and recent activity.
class EarningsWalletScreen extends ConsumerWidget {
  /// Creates an [EarningsWalletScreen] instance.
  const EarningsWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final balanceAsync = ref.watch(walletBalanceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Please log in'));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              children: [
                GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Column(
                    children: [
                      const Text('TOTAL EARNINGS',
                          style: TextStyle(
                              color: Colors.white54,
                              letterSpacing: 1.2,
                              fontSize: 12)),
                      const SizedBox(height: 8),
                      balanceAsync.when(
                        data: (balance) => Text(
                            '\$${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent)),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) =>
                            const Icon(Icons.error, color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                              LucideIcons.arrowUpRight, 'Withdraw'),
                          _buildActionButton(LucideIcons.fileText, 'Invoices'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Recent Activity',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTransactionTile('UI Design - Verasso', '+\$250.00',
                    '2 days ago', Colors.greenAccent),
                _buildTransactionTile(
                    'Logo Pack', '+\$50.00', '5 days ago', Colors.greenAccent),
                _buildTransactionTile(
                    'Bank Transfer', '-\$200.00', '1 week ago', Colors.white38),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            title: 'Could not load wallet',
            message: e.toString(),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTransactionTile(
      String title, String amount, String time, Color amountColor) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(time,
                  style: const TextStyle(fontSize: 12, color: Colors.white38)),
            ],
          ),
          Text(amount,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: amountColor)),
        ],
      ),
    );
  }
}
