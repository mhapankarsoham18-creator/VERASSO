import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating acid-base titration experiments.
class TitrationLabScreen extends StatefulWidget {
  /// Creates a [TitrationLabScreen] instance.
  const TitrationLabScreen({super.key});

  @override
  State<TitrationLabScreen> createState() => _TitrationLabScreenState();
}

class _AnalysisBox extends StatelessWidget {
  final double ph;

  const _AnalysisBox({required this.ph});

  @override
  Widget build(BuildContext context) {
    String status = "Acidic Solution";
    Color statusColor = Colors.blueAccent;
    if (ph > 6.9 && ph < 7.1) {
      status = "Neutral (End Point)";
      statusColor = Colors.greenAccent;
    } else if (ph >= 7.1) {
      status = "Basic Solution";
      statusColor = Colors.pinkAccent;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analysis',
              style: TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 4),
          Text(status,
              style:
                  TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DataRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TitrationLabScreenState extends State<TitrationLabScreen> {
  double _titrantVolume = 0.0; // mL
  final double _baseMolarity = 0.1; // NaOH
  final double _acidMolarity = 0.1; // HCl
  final double _acidVolume = 25.0; // mL

  bool _isTitrating = false;
  Timer? _titrationTimer;

  @override
  Widget build(BuildContext context) {
    final currentPH = _calculatePH();
    final indicatorColor = _getIndicatorColor(currentPH);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Titration Lab'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 15,
                          height: 350,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 13,
                                height: (350 * (1 - (_titrantVolume / 50.0)))
                                    .clamp(0.0, 350.0),
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: 80,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border:
                                    Border.all(color: Colors.white24, width: 2),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(5),
                                  bottomRight: Radius.circular(5),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  color: indicatorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: GlassContainer(
                margin: const EdgeInsets.only(top: 100, right: 16, bottom: 20),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Apparatus Control',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.amber)),
                    const SizedBox(height: 24),
                    _ControlButton(
                      label: _isTitrating ? 'Close Stopcock' : 'Open Stopcock',
                      icon: _isTitrating ? LucideIcons.pause : LucideIcons.play,
                      color:
                          _isTitrating ? Colors.redAccent : Colors.greenAccent,
                      onTap: _toggleTitration,
                    ),
                    const SizedBox(height: 12),
                    _ControlButton(
                      label: 'Add Single Drop',
                      icon: LucideIcons.droplets,
                      color: Colors.blueAccent,
                      onTap: _addDrop,
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 24),
                    _DataRow(
                        label: 'Titrant (NaOH)',
                        value: '${_titrantVolume.toStringAsFixed(2)} mL'),
                    _DataRow(
                        label: 'Sample (HCl)',
                        value: '${_acidVolume.toStringAsFixed(0)} mL'),
                    _DataRow(
                      label: 'Current pH',
                      value: currentPH.toStringAsFixed(2),
                      valueColor:
                          currentPH > 7 ? Colors.pinkAccent : Colors.blueAccent,
                    ),
                    const Spacer(),
                    _AnalysisBox(ph: currentPH),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titrationTimer?.cancel();
    super.dispose();
  }

  void _addDrop() {
    setState(() {
      _titrantVolume += 0.02; // Small drop
    });
  }

  double _calculatePH() {
    double molesH = _acidMolarity * (_acidVolume / 1000);
    double molesOH = _baseMolarity * (_titrantVolume / 1000);
    double totalVolume = (_acidVolume + _titrantVolume) / 1000;

    if (molesH > molesOH) {
      double concH = (molesH - molesOH) / totalVolume;
      return -0.43429 * math.log(concH > 0 ? concH : 1e-14);
    } else if (molesOH > molesH) {
      double concOH = (molesOH - molesH) / totalVolume;
      double pOH = -0.43429 * math.log(concOH > 0 ? concOH : 1e-14);
      return 14 - pOH;
    } else {
      return 7.0;
    }
  }

  Color _getIndicatorColor(double ph) {
    if (ph < 8.2) return Colors.blue.withValues(alpha: 25); // 0.1 * 255 approx
    double intensity = ((ph - 8.2) / (10.0 - 8.2)).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue.withValues(alpha: 25),
        Colors.pinkAccent.withValues(alpha: 153), intensity)!; // 0.6 * 255
  }

  void _toggleTitration() {
    if (_isTitrating) {
      _titrationTimer?.cancel();
    } else {
      _titrationTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _titrantVolume += 0.05; // 0.05 mL per 100ms
        });
      });
    }
    setState(() {
      _isTitrating = !_isTitrating;
    });
  }
}
