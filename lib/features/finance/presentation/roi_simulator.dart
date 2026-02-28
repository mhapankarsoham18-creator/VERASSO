import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/services/tutorial_service.dart';
import '../../../core/ui/tutorial_overlay.dart';
import '../../gamification/presentation/user_stats_controller.dart';
import '../tutorials/roi_tutorial.dart';

/// Interactive return‑on‑investment simulator that visualizes how recurring
/// contributions, time, and rate assumptions compound into future value.
class ROISimulator extends ConsumerStatefulWidget {
  /// Creates an [ROISimulator] instance.
  const ROISimulator({super.key});

  @override
  ConsumerState<ROISimulator> createState() => _ROISimulatorState();
}

class _ROISimulatorState extends ConsumerState<ROISimulator> {
  double principal = 10000;
  double rate = 10;
  double years = 10;
  double monthlyContribution = 500;
  bool adjustForInflation = false;
  double inflationRate = 3.0;

  @override
  Widget build(BuildContext context) {
    final spots = getChartData();
    final totalAmount = spots.last.y * 1000;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ROI Simulator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle),
            onPressed: _showTutorial,
            tooltip: 'Show Tutorial',
          ),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Educational tool. Not investment advice.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              // Result Card
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Estimated Future Value',
                        style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    if (adjustForInflation) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Real Value: \$${(totalAmount / pow(1 + inflationRate / 100, years)).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.greenAccent),
                      ),
                      const Text(
                        '(adjusted for inflation)',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chart
              GlassContainer(
                height: 250,
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Controls
              _buildSlider('Initial Principal', principal, 0, 100000, 1000,
                  (val) => setState(() => principal = val), '\$'),
              _buildSlider(
                  'Monthly Contribution',
                  monthlyContribution,
                  0,
                  5000,
                  100,
                  (val) => setState(() => monthlyContribution = val),
                  '\$'),
              _buildSlider('Expected Annual Rate', rate, 1, 30, 0.5,
                  (val) => setState(() => rate = val), '%'),
              _buildSlider('Time Period (Years)', years, 1, 50, 1,
                  (val) => setState(() => years = val), ' yrs'),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> getChartData() {
    List<FlSpot> spots = [];
    double total = principal;
    double r = rate / 100 / 12;
    int months = (years * 12).toInt();

    spots.add(const FlSpot(0, 0));

    for (int i = 1; i <= months; i++) {
      total = (total + monthlyContribution) * (1 + r);
      if (i % 12 == 0) {
        spots.add(FlSpot((i / 12).toDouble(), total / 1000));
      }
    }
    return spots;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final completed =
          await TutorialService.isTutorialCompleted(TutorialIds.roiSimulator);
      if (!completed && mounted) {
        _showTutorial();
      }
    });
  }

  Widget _buildSlider(String label, double value, double min, double max,
      double step, Function(double) onChanged, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                unit.startsWith('\$')
                    ? '\$${value.toStringAsFixed(0)}'
                    : '${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / (step == 0 ? 1 : step)).toInt(),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Colors.white12,
            onChanged: (val) => onChanged(val),
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: roiTutorialSteps,
        onComplete: () {
          TutorialService.markTutorialCompleted(TutorialIds.roiSimulator);
          ref.read(userStatsProvider.notifier).addXP(200);
        },
      ),
    );
  }
}
