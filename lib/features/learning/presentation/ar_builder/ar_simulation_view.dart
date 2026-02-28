import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../data/ar_project_model.dart';
import '../../data/circuit_simulation_service.dart';

/// AR Simulation View - shows simulation results overlaid on AR workspace
class ArSimulationView extends StatefulWidget {
  /// List of components forming the circuit.
  final List<ArComponent> components;

  /// List of electrical connections between components.
  final List<ComponentConnection> connections;

  /// Callback triggered when the simulation view is dismissed.
  final VoidCallback onClose;

  /// Creates an [ArSimulationView] instance.
  const ArSimulationView({
    super.key,
    required this.components,
    required this.connections,
    required this.onClose,
  });

  @override
  State<ArSimulationView> createState() => _ArSimulationViewState();
}

class _ArSimulationViewState extends State<ArSimulationView> {
  final _simulationService = CircuitSimulationService();
  SimulationResult? _result;
  bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Simulation results
            Expanded(
              child: _isSimulating
                  ? _buildLoadingState()
                  : _result != null
                      ? _buildResultsView()
                      : const SizedBox.shrink(),
            ),

            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  Widget _buildBottomControls() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _runSimulation,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Re-simulate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onClose,
            icon: const Icon(LucideIcons.check),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentStatesSection() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.lightbulb, color: Colors.greenAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'Component States',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._result!.componentStates.entries.map((entry) {
            final componentId = entry.key;
            final state = entry.value as Map<String, dynamic>;
            final component = widget.components.firstWhere(
              (c) => c.id == componentId,
              orElse: () => widget.components.first,
            );

            if (state.containsKey('isOn')) {
              final isOn = state['isOn'] as bool;
              final brightness = state['brightness'] as double? ?? 1.0;
              final color = state['color'] as String? ?? 'white';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      color: isOn ? _getColorFromString(color) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${component.name}: ${isOn ? "ON" : "OFF"}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (isOn)
                      Text(
                        '${(brightness * 100).toInt()}%',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          }),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorSection() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'Errors',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._result!.errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.redAccent)),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate().slideX(begin: -0.2);
  }

  Widget _buildHeader() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _result?.isValid == true
                    ? LucideIcons.checkCircle
                    : LucideIcons.alertCircle,
                color: _result?.isValid == true
                    ? Colors.greenAccent
                    : Colors.redAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                _result?.isValid == true ? 'Circuit Works!' : 'Circuit Issues',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blueAccent),
          const SizedBox(height: 24),
          const Text(
            'Simulating circuit...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ].animate(interval: 100.ms).fadeIn(),
      ),
    );
  }

  List<Widget> _buildMeasurementRows() {
    final rows = <Widget>[];

    for (final component in widget.components) {
      final voltage = _result!.voltages[component.id];
      final current = _result!.currents[component.id];

      if (voltage != null && current != null) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    component.name,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${voltage.toStringAsFixed(2)}V',
                  style: const TextStyle(color: Colors.greenAccent),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(current * 1000).toStringAsFixed(1)}mA',
                  style: const TextStyle(color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildReadingsSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.gauge, color: Colors.blueAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'Measurements',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildMeasurementRows(),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Errors
          if (_result!.errors.isNotEmpty) _buildErrorSection(),

          // Warnings
          if (_result!.warnings.isNotEmpty) _buildWarningSection(),

          // Component states
          if (_result!.isValid) _buildComponentStatesSection(),

          // Voltage & Current readings
          if (_result!.isValid) _buildReadingsSection(),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.alertTriangle,
                  color: Colors.orangeAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'Warnings',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._result!.warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: Colors.orangeAccent)),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate().slideX(begin: -0.2);
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  Future<void> _runSimulation() async {
    setState(() {
      _isSimulating = true;
    });

    try {
      final result = await _simulationService.simulate(
        widget.components,
        widget.connections,
      );

      setState(() {
        _result = result;
        _isSimulating = false;
      });
    } catch (e) {
      setState(() {
        _result = SimulationResult(
          isValid: false,
          errors: ['Simulation failed: $e'],
        );
        _isSimulating = false;
      });
    }
  }
}
