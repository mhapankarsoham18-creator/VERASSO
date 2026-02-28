import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../l10n/app_localizations.dart';
import '../../learning/presentation/simulations/finance/ledger_logic_screen.dart';
import 'accounting_simulator.dart';
import 'business_workflow.dart';
import 'economics_hub.dart';
import 'portfolio_tracker.dart';
import 'roi_simulator.dart';

/// Hub screen that links to all interactive finance and business simulations
/// (ROI, economics, accounting, business lifecycle, portfolio, and AR ledger).
class FinanceHub extends StatelessWidget {
  /// Creates a [FinanceHub] instance.
  const FinanceHub({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.businessAndFinance),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: ListView(
          padding:
              const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 40),
          children: [
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.amber.withValues(alpha: 0.15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.financeDisclaimer,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[100],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                l10n.financeSubtitle,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),

            _FinanceModuleCard(
              title: l10n.roiSimulator,
              subtitle: l10n.roiSubtitle,
              icon: LucideIcons.trendingUp,
              color: Colors.greenAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ROISimulator())),
            ),
            const SizedBox(height: 12),

            _FinanceModuleCard(
              title: l10n.economicsHub,
              subtitle: l10n.economicsSubtitle,
              icon: LucideIcons.barChart3,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EconomicsHub())),
            ),
            const SizedBox(height: 12),

            _FinanceModuleCard(
              title: l10n.accountingSimulator,
              subtitle: l10n.accountingSubtitle,
              icon: LucideIcons.calculator,
              color: Colors.purpleAccent,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccountingSimulator())),
            ),
            const SizedBox(height: 12),

            _FinanceModuleCard(
              title: l10n.businessWorkflow,
              subtitle: l10n.businessSubtitle,
              icon: LucideIcons.briefcase,
              color: Colors.orangeAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BusinessWorkflow())),
            ),
            const SizedBox(height: 12),

            _FinanceModuleCard(
              title: l10n.portfolioTracker,
              subtitle: l10n.portfolioSubtitle,
              icon: LucideIcons.pieChart,
              color: Colors.cyanAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PortfolioTracker())),
            ),
            _FinanceModuleCard(
              title: l10n.ledgerLogicAR,
              subtitle: l10n.ledgerLogicSubtitle,
              icon: LucideIcons.box,
              color: Colors.pinkAccent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LedgerLogicScreen())),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.yourProgress,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(l10n.modules, '5', LucideIcons.bookOpen),
                      _buildStatItem(l10n.xpEarned, '0', LucideIcons.award),
                      _buildStatItem(l10n.badges, '0/5', LucideIcons.trophy),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}

class _FinanceModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FinanceModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
