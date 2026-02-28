import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/services/tutorial_service.dart';
import '../../../core/ui/tutorial_overlay.dart';
import '../../gamification/presentation/user_stats_controller.dart';
import '../tutorials/economics_tutorial.dart';

/// Visual economics playground for exploring supply/demand curves and
/// equilibrium under different macro scenarios.
class EconomicsHub extends ConsumerStatefulWidget {
  /// Creates an [EconomicsHub] instance.
  const EconomicsHub({super.key});

  @override
  ConsumerState<EconomicsHub> createState() => _EconomicsHubState();
}

class _EconomicsHubState extends ConsumerState<EconomicsHub> {
  double demandShift = 0;
  double supplyShift = 0;

  @override
  Widget build(BuildContext context) {
    final eq = getEquilibrium();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Economics Hub'),
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
            children: [
              // Economic Indicators
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Economic Indicators',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildIndicator(
                            'GDP Growth', '+2.5%', Colors.greenAccent),
                        _buildIndicator(
                            'Inflation', '3.2%', Colors.orangeAccent),
                        _buildIndicator(
                            'Unemployment', '4.1%', Colors.blueAccent),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Result Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Price', '\$${eq.dy.toStringAsFixed(1)}'),
                    _buildStat('Quantity', eq.dx.toStringAsFixed(0)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Graph
              GlassContainer(
                height: 350,
                padding: const EdgeInsets.all(20),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 100,
                    minY: 0,
                    maxY: 150,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 25,
                      verticalInterval: 25,
                      getDrawingHorizontalLine: (value) =>
                          const FlLine(color: Colors.white10, strokeWidth: 1),
                      getDrawingVerticalLine: (value) =>
                          const FlLine(color: Colors.white10, strokeWidth: 1),
                    ),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 30)),
                      bottomTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 30)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                        show: true, border: Border.all(color: Colors.white24)),
                    lineBarsData: [
                      // Demand Curve
                      LineChartBarData(
                        spots: getDemandSpots(),
                        isCurved: false,
                        color: Colors.redAccent,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                      // Supply Curve
                      LineChartBarData(
                        spots: getSupplySpots(),
                        isCurved: false,
                        color: Colors.blueAccent,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                            y: eq.dy,
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [5, 5]),
                      ],
                      verticalLines: [
                        VerticalLine(
                            x: eq.dx,
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [5, 5]),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Demand', Colors.redAccent),
                  const SizedBox(width: 20),
                  _buildLegendItem('Supply', Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 32),

              // Controls
              _buildControlSlider('Demand Shift', demandShift, -50, 50,
                  (v) => setState(() => demandShift = v)),
              _buildControlSlider('Supply Shift', supplyShift, -50, 50,
                  (v) => setState(() => supplyShift = v)),

              const SizedBox(height: 20),

              // Preset Scenarios
              const Text('Market Scenarios:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildScenarioChip('Recession', -20, 10, Colors.redAccent),
                  _buildScenarioChip('Boom', 30, -15, Colors.greenAccent),
                  _buildScenarioChip('Pandemic', -30, -20, Colors.orangeAccent),
                  _buildScenarioChip(
                      'Crisis', -40, 20, Colors.deepOrangeAccent),
                  _buildScenarioChip('Reset', 0, 0, Colors.blueAccent),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                'Shift curves to see how equilibrium price and quantity change in response to market shocks.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Initial curves: P = 100 - Q (Demand), P = 20 + Q (Supply)
  // Shifted: P = (100 + demandShift) - Q, P = (20 + supplyShift) + Q

  List<FlSpot> getDemandSpots() {
    return List.generate(11, (i) {
      double q = i * 10.0;
      double p = (100 + demandShift) - q;
      return FlSpot(q, p < 0 ? 0 : p);
    });
  }

  Offset getEquilibrium() {
    // (100 + demandShift) - Q = (20 + supplyShift) + Q
    // 80 + demandShift - supplyShift = 2Q
    double q = (80 + demandShift - supplyShift) / 2;
    double p = (100 + demandShift) - q;
    return Offset(q, p);
  }

  List<FlSpot> getSupplySpots() {
    return List.generate(11, (i) {
      double q = i * 10.0;
      double p = (20 + supplyShift) + q;
      return FlSpot(q, p < 0 ? 0 : p);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final completed =
          await TutorialService.isTutorialCompleted(TutorialIds.economicsHub);
      if (!completed && mounted) {
        _showTutorial();
      }
    });
  }

  Widget _buildControlSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildScenarioChip(
      String label, double demandChange, double supplyChange, Color color) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.3),
      side: BorderSide(color: color, width: 1),
      onPressed: () {
        setState(() {
          demandShift = demandChange;
          supplyShift = supplyChange;
        });
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent)),
      ],
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: economicsTutorialSteps,
        onComplete: () {
          TutorialService.markTutorialCompleted(TutorialIds.economicsHub);
          ref.read(userStatsProvider.notifier).addXP(200);
        },
      ),
    );
  }
}
