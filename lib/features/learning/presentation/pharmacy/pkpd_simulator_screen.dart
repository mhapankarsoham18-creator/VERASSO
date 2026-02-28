import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A simulator for pharmacokinetic and pharmacodynamic (PK/PD) drug modeling.
class PKPDSimulatorScreen extends StatefulWidget {
  /// Creates a [PKPDSimulatorScreen] instance.
  const PKPDSimulatorScreen({super.key});

  @override
  State<PKPDSimulatorScreen> createState() => _PKPDSimulatorScreenState();
}

class _PKPDSimulatorScreenState extends State<PKPDSimulatorScreen> {
  double _dose = 500.0; // mg
  double _ka = 1.5; // Absorption rate constant
  double _ke = 0.2; // Elimination rate constant
  double _volume = 10.0; // Distribution volume (L)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('PK/PD Simulator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),

            // Graph Section
            Expanded(
              flex: 3,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.lineChart, color: Colors.blueAccent),
                        SizedBox(width: 12),
                        Text('Plasma Concentration Curve',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 24,
                          minY: 0,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 10,
                            verticalInterval: 4,
                            getDrawingHorizontalLine: (value) => const FlLine(
                                color: Colors.white10, strokeWidth: 1),
                            getDrawingVerticalLine: (value) => const FlLine(
                                color: Colors.white10, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (v, m) => Text(
                                        '${v.toInt()}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38)))),
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) => Text(
                                        '${v.toInt()}h',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38)))),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _generateData(),
                              isCurved: true,
                              color: Colors.blueAccent,
                              barWidth: 4,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blueAccent.withValues(alpha: 0.3),
                                    Colors.blueAccent.withValues(alpha: 0)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls Section
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSlider('Dose (mg)', _dose, 100, 1000,
                        (v) => setState(() => _dose = v)),
                    _buildSlider('Abs. Rate (ka)', _ka, 0.1, 3.0,
                        (v) => setState(() => _ka = v)),
                    _buildSlider('Elim. Rate (ke)', _ke, 0.01, 1.0,
                        (v) => setState(() => _ke = v)),
                    _buildSlider('Volume (Vd)', _volume, 1.0, 50.0,
                        (v) => setState(() => _volume = v)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              Text(value.toStringAsFixed(2),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateData() {
    List<FlSpot> spots = [];
    // Simple 1-compartment model: C = (D*ka / V*(ka-ke)) * (e^-ke*t - e^-ka*t)
    for (double t = 0; t <= 24; t += 0.5) {
      double concentration = (_dose * _ka / (_volume * (_ka - _ke))) *
          (math.exp(-_ke * t) - math.exp(-_ka * t));
      spots.add(FlSpot(t, concentration.clamp(0.0, 1000.0)));
    }
    return spots;
  }
}
