import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/finance_repository.dart';

/// Visual analytics view for a user's earnings and income sources.
///
/// Uses simple bar and pie charts to surface monthly trends and income
/// breakdowns derived from [FinanceRepository] data.
class AnalyticsScreen extends ConsumerWidget {
  /// Creates an [AnalyticsScreen] instance.
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Growth Analytics'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: SafeArea(
          child: userId == null
              ? const Center(child: Text('Please log in'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMonthlyChart(ref, userId),
                      const SizedBox(height: 16),
                      _buildIncomeSources(ref, userId),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Builds the income breakdown pie chart and legend for [userId].
  Widget _buildIncomeSources(WidgetRef ref, String userId) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(financeRepositoryProvider).getIncomeBreakdown(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final data = snapshot.data!;
        if (data.isEmpty) {
          return const GlassContainer(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text('No income data available',
                    style: TextStyle(color: Colors.white54))),
          );
        }

        final total = data.values.fold(0.0, (sum, val) => sum + val);
        final List<Color> colors = [
          Colors.purpleAccent,
          Colors.blueAccent,
          Colors.orangeAccent,
          Colors.greenAccent,
          Colors.redAccent
        ];

        return GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Income Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections:
                              data.entries.toList().asMap().entries.map((e) {
                            final index = e.key;
                            final entry = e.value;
                            final color = colors[index % colors.length];
                            final isLarge = entry.value / total >
                                0.2; // Highlight big chunks

                            return PieChartSectionData(
                              color: color,
                              value: entry.value,
                              title:
                                  '${((entry.value / total) * 100).toInt()}%',
                              radius: isLarge ? 60 : 50,
                              titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            data.entries.toList().asMap().entries.map((e) {
                          final index = e.key;
                          final entry = e.value;
                          final color = colors[index % colors.length];
                          return _RowStat(
                              entry.key, '\$${entry.value.toInt()}', color);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a compact bar chart of monthly earnings for [userId].
  Widget _buildMonthlyChart(WidgetRef ref, String userId) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(financeRepositoryProvider).getMonthlyEarnings(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final data = snapshot.data!;
        if (data.values.every((v) => v == 0)) return const SizedBox.shrink();

        final maxVal = data.values.reduce((a, b) => a > b ? a : b);

        return GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Earnings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: data.entries.map((e) {
                    final heightFactor = maxVal > 0 ? e.value / maxVal : 0.0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (e.value > 0)
                          Text('\$${e.value.toInt()}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.greenAccent)),
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: 150 * heightFactor + 10, // Min height 10
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(e.key,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Simple label/value row with a colored dot used in the income legend.
class _RowStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RowStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
