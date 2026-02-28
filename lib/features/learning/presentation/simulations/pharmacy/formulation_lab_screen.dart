import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/services/battery_saver_service.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/resource_service.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/finance/data/financial_sandbox_service.dart';
import 'package:verasso/features/learning/core/generative_lab_service.dart';

/// Represents an excipient used in pharmaceutical formulation.
class Excipient {
  /// The name of the excipient.
  final String name;

  /// The type or category of the excipient (e.g., Filler).
  final String type;

  /// The color associated with the excipient.
  final Color color;

  /// The impact of this excipient on formulation stability.
  final double stabilityImpact;

  /// Creates an [Excipient] instance.
  Excipient({
    required this.name,
    required this.type,
    required this.color,
    required this.stabilityImpact,
  });
}

/// A laboratory screen for simulating the formulation of pharmaceutical products.
class FormulationLabScreen extends ConsumerStatefulWidget {
  /// Creates a [FormulationLabScreen] instance.
  const FormulationLabScreen({super.key});

  @override
  ConsumerState<FormulationLabScreen> createState() =>
      _FormulationLabScreenState();
}

class _FormulationLabScreenState extends ConsumerState<FormulationLabScreen> {
  LabScenario? _currentScenario;
  final List<Excipient> _inventory = [
    Excipient(
        name: 'Lactose',
        type: 'Filler',
        color: Colors.white,
        stabilityImpact: 0.1),
    Excipient(
        name: 'Magnesium Stearate',
        type: 'Lubricant',
        color: Colors.grey,
        stabilityImpact: -0.2),
    Excipient(
        name: 'Starch',
        type: 'Binder',
        color: Colors.yellow.shade100,
        stabilityImpact: 0.3),
    Excipient(
        name: 'PVP K30',
        type: 'Binder',
        color: Colors.amber.shade200,
        stabilityImpact: 0.4),
    Excipient(
        name: 'Talc',
        type: 'Glidant',
        color: Colors.blue.shade100,
        stabilityImpact: 0.05),
    Excipient(
        name: 'Cellulose',
        type: 'Disintegrant',
        color: Colors.green.shade100,
        stabilityImpact: 0.2),
  ];

  final List<Excipient> _mixture = [];
  double _stabilityScore = 0.5; // Starts at neutral

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Virtual Formulation Lab'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            onPressed: () => setState(() {
              _mixture.clear();
              _stabilityScore = 0.5;
            }),
          ),
        ],
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Top Header: Scenario & Peers
            Padding(
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentScenario?.title ?? 'Formulation Lab',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(_currentScenario?.complexity ?? 'Medium Complexity',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                  // Mesh Peer Presence Indicator
                  const _PeerPresenceIndicator(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lab Equipment & Finance Integration
            Expanded(
              flex: 4,
              child: GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Icon(LucideIcons.flaskConical,
                            size: 100, color: Colors.blueAccent),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Precision Scale Upgrade',
                              style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () => _purchaseUpgrade(),
                            child: const Text('Unlock (\$50)'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),

            // Mixing Area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Inventory
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: _inventory.length,
                        itemBuilder: (context, index) {
                          final excipient = _inventory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Draggable<Excipient>(
                              data: excipient,
                              feedback: _buildExcipientCard(excipient,
                                  isFeedback: true),
                              childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: _buildExcipientCard(excipient)),
                              child: _buildExcipientCard(excipient),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Mixing Bowl (Drag Target)
                    Expanded(
                      flex: 2,
                      child: DragTarget<Excipient>(
                        onAcceptWithDetails: (details) {
                          _addExcipient(details.data);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return GlassContainer(
                            color: candidateData.isNotEmpty
                                ? Colors.blue.withValues(alpha: 0.3)
                                : null,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _mixture.isEmpty
                                      ? LucideIcons.beaker
                                      : LucideIcons.testTube,
                                  size: 80,
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _mixture.isEmpty
                                      ? 'Drag excipients here to mix'
                                      : '${_mixture.length} components mixed',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                if (_mixture.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _mixture
                                        .map((e) => Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                  color: e.color,
                                                  shape: BoxShape.circle),
                                            ))
                                        .toList(),
                                  ),
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // On-Demand Asset Loading Overlay
            if (!ref
                .watch(resourceServiceProvider)
                .isResourceAvailable('lab_3d_engine'))
              Positioned.fill(
                child: GlassContainer(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Optimizing Lab Environment...\n${(ref.watch(resourceServiceProvider).getProgress('lab_3d_engine') * 100).toInt()}%',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(resourceServiceProvider)
                            .ensureResource('lab_3d_engine'),
                        child: const Text('Download Assets'),
                      ),
                    ],
                  ),
                ),
              ),

            // Stability Analysis
            Expanded(
              flex: 2,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stability Prediction',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '${(_stabilityScore * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _stabilityScore > 0.7
                                ? Colors.greenAccent
                                : (_stabilityScore < 0.4
                                    ? Colors.redAccent
                                    : Colors.amberAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!ref
                        .watch(batterySaverProvider)
                        .isEnabled) // Hide chart in power save
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _generateStabilitySpots(),
                                isCurved: true,
                                color: _stabilityScore > 0.7
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: (_stabilityScore > 0.7
                                          ? Colors.greenAccent
                                          : Colors.blueAccent)
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Text('Graph hidden to save power',
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ),
                      ),
                    const Text('30-Day Stability Projection',
                        style: TextStyle(fontSize: 10, color: Colors.white38)),
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
  void initState() {
    super.initState();
    _initScenario();
  }

  void _addExcipient(Excipient excipient) {
    setState(() {
      _mixture.add(excipient);
      _updateStability();
    });
  }

  Widget _buildExcipientCard(Excipient excipient, {bool isFeedback = false}) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      width: isFeedback ? 150 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: excipient.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(excipient.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          Text(excipient.type,
              style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }

  List<FlSpot> _generateStabilitySpots() {
    // Uses a more realistic decay model based on current excipients
    // Stability affects both initial level and rate of descent
    return List.generate(10, (index) {
      double t = index.toDouble(); // Time in arbitrary units
      // A common stability decay model: y = S0 * e^(-kt)
      // where k is higher if stability is lower.
      double k = (1.5 - _stabilityScore) * 0.15;
      double y = (_stabilityScore * exp(-k * t)).clamp(0.0, 1.0);
      return FlSpot(t, y);
    });
  }

  void _initScenario() {
    _currentScenario =
        ref.read(generativeLabServiceProvider).generateScenario();
  }

  Future<void> _purchaseUpgrade() async {
    final success = await ref
        .read(financialSandboxProvider.notifier)
        .processPayment(50.0, 'Precision Scale');

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment Upgraded Successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Funds in Wallet')),
      );
    }
  }

  void _updateStability() {
    double base = 0.5;
    for (var e in _mixture) {
      base += e.stabilityImpact;
    }
    setState(() {
      _stabilityScore = base.clamp(0.0, 1.0);
    });
  }
}

class _PeerPresenceIndicator extends ConsumerWidget {
  const _PeerPresenceIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesh = ref.watch(bluetoothMeshServiceProvider);
    // connectedEndpoints is the correct property in BluetoothMeshService
    final peerCount = mesh.connectedEndpointsCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.users, size: 14, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text('$peerCount Peers Nearby',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent)),
        ],
      ),
    );
  }
}
