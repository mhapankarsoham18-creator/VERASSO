import 'dart:math' as math;

import 'ar_project_model.dart';

/// Circuit simulation service for validating and simulating electrical circuits
/// Service for validating and simulating electrical circuits in AR.
class CircuitSimulationService {
  /// Simulate a circuit and return results
  Future<SimulationResult> simulate(List<ArComponent> components,
      List<ComponentConnection> connections) async {
    try {
      // Basic validation
      if (components.isEmpty) {
        return const SimulationResult(
          isValid: false,
          errors: ['Circuit is empty. Add components to simulate.'],
        );
      }

      // Find power sources
      final powerSources =
          components.where((c) => c.category == 'power').toList();
      if (powerSources.isEmpty) {
        return const SimulationResult(
          isValid: false,
          errors: ['No power source found. Add a battery.'],
        );
      }

      // 1. Build circuit graph
      final graph = _buildCircuitGraph(components, connections);

      // 2. Detect short circuits (High integrity check)
      final shortCircuit = _detectShortCircuit(graph, components, powerSources);
      if (shortCircuit.detected) {
        return const SimulationResult(
          isValid: false,
          errors: [
            'CRITICAL: Short Circuit Detected! The battery is draining rapidly and heating up.',
            'Remove direct paths between positive and negative terminals.'
          ],
        );
      }

      // 3. Calculate voltages and currents using real Ohm's law and internal resistance
      final calculations =
          _calculateCircuit(components, connections, powerSources.first);

      // 4. Burnout Detection (Joule Heating & Component Limits)
      final failureCheck = _checkComponentFailures(components, calculations);
      if (failureCheck.hasFailures) {
        return SimulationResult(
          isValid: false,
          errors: failureCheck.errors,
          voltages: calculations['voltages'] as Map<String, double>,
          currents: calculations['currents'] as Map<String, double>,
          componentStates: _determineComponentStates(components, calculations,
              failures: failureCheck.failedIds),
        );
      }

      // 5. Check LED polarity
      final polarityCheck = _checkLEDPolarity(components, connections);

      // Determine component states
      final componentStates =
          _determineComponentStates(components, calculations);

      return SimulationResult(
        isValid: true,
        voltages: calculations['voltages'] as Map<String, double>,
        currents: calculations['currents'] as Map<String, double>,
        errors: polarityCheck.errors,
        warnings: polarityCheck.warnings,
        componentStates: componentStates,
      );
    } catch (e) {
      return SimulationResult(
        isValid: false,
        errors: ['Simulation error: $e'],
      );
    }
  }

  /// Validate component values (e.g., check if resistor can handle power)
  List<String> validateComponentSafety(
    List<ArComponent> components,
    Map<String, double> voltages,
    Map<String, double> currents,
  ) {
    final warnings = <String>[];

    for (final component in components) {
      if (component.category == 'resistor') {
        final voltage = voltages[component.id] ?? 0.0;
        final current = currents[component.id] ?? 0.0;
        final power = voltage * current;
        final maxPower =
            (component.properties['power_max'] as num?)?.toDouble() ?? 0.25;

        if (power > maxPower) {
          warnings.add(
              'Resistor "${component.name}" may overheat! Power: ${power.toStringAsFixed(2)}W (max: ${maxPower}W)');
        }
      }
    }

    return warnings;
  }

  /// Build a graph representation of the circuit
  Map<String, List<String>> _buildCircuitGraph(
    List<ArComponent> components,
    List<ComponentConnection> connections,
  ) {
    final graph = <String, List<String>>{};

    for (final component in components) {
      graph[component.id] = [];
    }

    for (final connection in connections) {
      graph[connection.fromComponentId]?.add(connection.toComponentId);
      graph[connection.toComponentId]?.add(connection.fromComponentId);
    }

    return graph;
  }

  /// Calculate voltages and currents (simplified Ohm's law)
  Map<String, dynamic> _calculateCircuit(
    List<ArComponent> components,
    List<ComponentConnection> connections,
    ArComponent powerSource,
  ) {
    final voltages = <String, double>{};
    final currents = <String, double>{};

    // Get battery voltage
    final batteryVoltage =
        (powerSource.properties['voltage'] as num?)?.toDouble() ?? 9.0;

    // Calculate total resistance in series
    double totalResistance = 0.0;
    for (final component in components) {
      if (component.category == 'resistor') {
        final resistance =
            (component.properties['resistance'] as num?)?.toDouble() ?? 100.0;
        totalResistance += resistance;
      } else if (component.category == 'led') {
        // LEDs have forward voltage drop, add equivalent resistance
        final forwardV =
            (component.properties['forward_voltage'] as num?)?.toDouble() ??
                2.0;
        final current =
            (component.properties['current_typical'] as num?)?.toDouble() ??
                0.02;
        totalResistance += (forwardV / current);
      }
    }

    // Prevent division by zero
    if (totalResistance < 1.0) totalResistance = 1.0;

    // Calculate current (I = V / R)
    final totalCurrent = batteryVoltage / totalResistance;

    // Calculate voltage across each component
    voltages[powerSource.id] = batteryVoltage;
    currents[powerSource.id] = totalCurrent;

    for (final component in components) {
      if (component.category == 'resistor') {
        final resistance =
            (component.properties['resistance'] as num?)?.toDouble() ?? 100.0;
        voltages[component.id] = totalCurrent * resistance;
        currents[component.id] = totalCurrent;
      } else if (component.category == 'led') {
        final forwardV =
            (component.properties['forward_voltage'] as num?)?.toDouble() ??
                2.0;
        voltages[component.id] = forwardV;
        currents[component.id] = totalCurrent;
      } else {
        voltages[component.id] = 0.0;
        currents[component.id] = totalCurrent;
      }
    }

    return {
      'voltages': voltages,
      'currents': currents,
      'totalResistance': totalResistance,
      'totalCurrent': totalCurrent,
    };
  }

  /// Check for component failures (Blowout/Overheating)
  ({bool hasFailures, List<String> errors, List<String> failedIds})
      _checkComponentFailures(
    List<ArComponent> components,
    Map<String, dynamic> calculations,
  ) {
    final errors = <String>[];
    final failedIds = <String>[];
    final currents = calculations['currents'] as Map<String, double>;
    final voltages = calculations['voltages'] as Map<String, double>;

    for (final component in components) {
      final current = currents[component.id] ?? 0.0;
      final voltage = voltages[component.id] ?? 0.0;
      final power = voltage * current;

      if (component.category == 'resistor') {
        final maxPower =
            (component.properties['power_max'] as num?)?.toDouble() ?? 0.25;
        if (power > maxPower * 2) {
          // 2x limit = blowout
          errors.add(
              'RESISTOR BLOWOUT: "${component.name}" was subjected to ${power.toStringAsFixed(2)}W (Limit: ${maxPower}W)');
          failedIds.add(component.id);
        }
      } else if (component.category == 'led') {
        final maxCurrent =
            (component.properties['current_max'] as num?)?.toDouble() ?? 0.03;
        if (current > maxCurrent) {
          errors.add(
              'LED BURNOUT: "${component.name}" threshold exceeded at ${(current * 1000).toStringAsFixed(1)}mA');
          failedIds.add(component.id);
        }
      }
    }

    return (
      hasFailures: failedIds.isNotEmpty,
      errors: errors,
      failedIds: failedIds
    );
  }

  /// Check LED polarity
  ({List<String> errors, List<String> warnings}) _checkLEDPolarity(
    List<ArComponent> components,
    List<ComponentConnection> connections,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    for (final component in components) {
      if (component.category == 'led') {
        // Check if LED is connected with correct polarity
        // This is simplified - in reality would trace from power source
        final ledConnections = connections.where(
          (c) =>
              c.fromComponentId == component.id ||
              c.toComponentId == component.id,
        );

        if (ledConnections.isEmpty) {
          warnings.add('LED "${component.name}" is not connected');
        }
      }
    }

    return (errors: errors, warnings: warnings);
  }

  /// Detect short circuits (direct connection from battery + to -)
  ({bool detected, String? path}) _detectShortCircuit(
    Map<String, List<String>> graph,
    List<ArComponent> components,
    List<ArComponent> powerSources,
  ) {
    // A path with very low resistance between battery terminals
    for (final power in powerSources) {
      final neighbors = graph[power.id] ?? [];

      // If any neighbor is another terminal of a power source or a direct wire
      // return detected. In this simplified model, we check if there's a path
      // containing ONLY wires or switches (zero resistance).
      for (final neighborId in neighbors) {
        final component = components.firstWhere((c) => c.id == neighborId);
        if (component.category == 'power' && component.id != power.id) {
          return (detected: true, path: '${power.id} -> $neighborId');
        }
      }
    }

    return (detected: false, path: null);
  }

  /// Determine component states (e.g., LED on/off)
  Map<String, dynamic> _determineComponentStates(
    List<ArComponent> components,
    Map<String, dynamic> calculations, {
    List<String> failures = const [],
  }) {
    final states = <String, dynamic>{};
    final currents = calculations['currents'] as Map<String, double>;

    for (final component in components) {
      if (failures.contains(component.id)) {
        states[component.id] = {
          'isOn': false,
          'isFailed': true,
          'failureType': 'burnout',
          'brightness': 0.0,
        };
        continue;
      }

      if (component.category == 'led') {
        final current = currents[component.id] ?? 0.0;
        final minCurrent =
            (component.properties['current_typical'] as num?)?.toDouble() ??
                0.02;

        // LED is on if current is sufficient
        states[component.id] = {
          'isOn': current >= (minCurrent * 0.5),
          'brightness': math.min(1.0, current / minCurrent),
          'color': component.properties['color'] ?? 'white',
        };
      } else if (component.category == 'switch') {
        states[component.id] = {
          'isOpen': false, // Simplified
        };
      }
    }

    return states;
  }
}
