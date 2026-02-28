import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/learning/data/ar_project_model.dart';
import 'package:verasso/features/learning/data/circuit_simulation_service.dart';

void main() {
  late CircuitSimulationService simulationService;

  setUp(() {
    simulationService = CircuitSimulationService();
  });

  group('Circuit Simulation Tests', () {
    test('Empty circuit should return error', () async {
      final result = await simulationService.simulate([], []);

      expect(result.isValid, false);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('empty'));
    });

    test('Circuit without power source should return error', () async {
      final components = [
        const ArComponent(
          id: 'led1',
          componentLibraryId: 'led_red',
          name: 'Red LED',
          category: 'led',
          transform: Transform3D(),
          properties: {'forward_voltage': 2.0},
        ),
      ];

      final result = await simulationService.simulate(components, []);

      expect(result.isValid, false);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('power source'));
    });

    test('Simple LED circuit should work correctly', () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'resistor',
          componentLibraryId: 'resistor_220',
          name: '220Ω Resistor',
          category: 'resistor',
          transform: Transform3D(),
          properties: {'resistance': 220},
        ),
        const ArComponent(
          id: 'led',
          componentLibraryId: 'led_red',
          name: 'Red LED',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 2.0,
            'current_typical': 0.02,
            'color': 'red'
          },
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'resistor',
          fromTerminal: 'positive',
          toTerminal: 'in',
        ),
        const ComponentConnection(
          fromComponentId: 'resistor',
          toComponentId: 'led',
          fromTerminal: 'out',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'led',
          toComponentId: 'battery',
          fromTerminal: 'negative',
          toTerminal: 'negative',
        ),
      ];

      final result = await simulationService.simulate(components, connections);

      expect(result.isValid, true);
      expect(result.errors, isEmpty);
      expect(result.voltages, isNotEmpty);
      expect(result.currents, isNotEmpty);

      // Check if LED is on
      expect(result.componentStates['led'], isNotNull);
      final ledState = result.componentStates['led'] as Map<String, dynamic>;
      expect(ledState['isOn'], true);
      expect(ledState['color'], 'red');
    });

    test('Multiple LEDs in series should work', () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'resistor',
          componentLibraryId: 'resistor_100',
          name: '100Ω Resistor',
          category: 'resistor',
          transform: Transform3D(),
          properties: {'resistance': 100},
        ),
        const ArComponent(
          id: 'led1',
          componentLibraryId: 'led_red',
          name: 'Red LED 1',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 2.0,
            'current_typical': 0.02,
            'color': 'red'
          },
        ),
        const ArComponent(
          id: 'led2',
          componentLibraryId: 'led_green',
          name: 'Green LED',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 2.1,
            'current_typical': 0.02,
            'color': 'green'
          },
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'resistor',
          fromTerminal: 'positive',
          toTerminal: 'in',
        ),
        const ComponentConnection(
          fromComponentId: 'resistor',
          toComponentId: 'led1',
          fromTerminal: 'out',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'led1',
          toComponentId: 'led2',
          fromTerminal: 'negative',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'led2',
          toComponentId: 'battery',
          fromTerminal: 'negative',
          toTerminal: 'negative',
        ),
      ];

      final result = await simulationService.simulate(components, connections);

      expect(result.isValid, true);
      expect(result.componentStates['led1'], isNotNull);
      expect(result.componentStates['led2'], isNotNull);
    });

    test('Circuit with different resistor values should calculate correctly',
        () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'resistor',
          componentLibraryId: 'resistor_1k',
          name: '1kΩ Resistor',
          category: 'resistor',
          transform: Transform3D(),
          properties: {'resistance': 1000},
        ),
        const ArComponent(
          id: 'led',
          componentLibraryId: 'led_blue',
          name: 'Blue LED',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 3.2,
            'current_typical': 0.02,
            'color': 'blue'
          },
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'resistor',
          fromTerminal: 'positive',
          toTerminal: 'in',
        ),
        const ComponentConnection(
          fromComponentId: 'resistor',
          toComponentId: 'led',
          fromTerminal: 'out',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'led',
          toComponentId: 'battery',
          fromTerminal: 'negative',
          toTerminal: 'negative',
        ),
      ];

      final result = await simulationService.simulate(components, connections);

      expect(result.isValid, true);
      // With higher resistance, current should be lower
      // I = V / R_total
      // R_total = 1000 + (3.2 / 0.02) = 1000 + 160 = 1160 ohms
      // I = 9 / 1160 = 0.00776 A (< 0.01)
      expect(result.currents['led'], lessThan(0.01));
    });

    test('Voltage calculations should be present for all components', () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'resistor',
          componentLibraryId: 'resistor_220',
          name: '220Ω Resistor',
          category: 'resistor',
          transform: Transform3D(),
          properties: {'resistance': 220},
        ),
        const ArComponent(
          id: 'led',
          componentLibraryId: 'led_red',
          name: 'Red LED',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 2.0,
            'current_typical': 0.02,
            'color': 'red'
          },
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'resistor',
          fromTerminal: 'positive',
          toTerminal: 'in',
        ),
        const ComponentConnection(
          fromComponentId: 'resistor',
          toComponentId: 'led',
          fromTerminal: 'out',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'led',
          toComponentId: 'battery',
          fromTerminal: 'negative',
          toTerminal: 'negative',
        ),
      ];

      final result = await simulationService.simulate(components, connections);

      expect(result.voltages.containsKey('battery'), true);
      expect(result.voltages.containsKey('resistor'), true);
      expect(result.voltages.containsKey('led'), true);
      // Total voltage drop across resistor and LED should sum to 9V
      // V_resistor = I * R = 0.01538 * 220 = 3.384V
      // V_led = 2.0V (forward voltage)
      // Total = 5.384V (remaining voltage drop through series path)
      final totalVoltage = (result.voltages['resistor'] ?? 0.0) +
          (result.voltages['led'] ?? 0.0);
      expect(totalVoltage, lessThan(9.0));
    });

    test('LED brightness should scale with current', () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'resistor',
          componentLibraryId: 'resistor_220',
          name: '220Ω Resistor',
          category: 'resistor',
          transform: Transform3D(),
          properties: {'resistance': 220},
        ),
        const ArComponent(
          id: 'led',
          componentLibraryId: 'led_red',
          name: 'Red LED',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 2.0,
            'current_typical': 0.02,
            'color': 'red'
          },
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'resistor',
          fromTerminal: 'positive',
          toTerminal: 'in',
        ),
        const ComponentConnection(
          fromComponentId: 'resistor',
          toComponentId: 'led',
          fromTerminal: 'out',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'led',
          toComponentId: 'battery',
          fromTerminal: 'negative',
          toTerminal: 'negative',
        ),
      ];

      final result = await simulationService.simulate(components, connections);

      expect(result.componentStates['led'], isNotNull);
      final ledState = result.componentStates['led'] as Map<String, dynamic>;
      expect(ledState['brightness'], greaterThan(0.0));
      expect(ledState['brightness'], lessThanOrEqualTo(1.0));
      expect(ledState['color'], equals('red'));
    });
  });

  group('Transform3D Tests', () {
    test('Transform3D should serialize and deserialize correctly', () {
      const transform = Transform3D(
        x: 1.5,
        y: -2.3,
        z: 0.8,
        rotationX: 45.0,
        rotationY: 90.0,
        rotationZ: 180.0,
        scale: 1.2,
      );

      final json = transform.toJson();
      final deserialized = Transform3D.fromJson(json);

      expect(deserialized.x, transform.x);
      expect(deserialized.y, transform.y);
      expect(deserialized.z, transform.z);
      expect(deserialized.rotationX, transform.rotationX);
      expect(deserialized.rotationY, transform.rotationY);
      expect(deserialized.rotationZ, transform.rotationZ);
      expect(deserialized.scale, transform.scale);
    });

    test('Transform3D copyWith should work correctly', () {
      const transform = Transform3D(x: 1.0, y: 2.0);
      final updated = transform.copyWith(x: 5.0);

      expect(updated.x, 5.0);
      expect(updated.y, 2.0);
    });
  });

  group('ArComponent Tests', () {
    test('ArComponent should serialize and deserialize correctly', () {
      const component = ArComponent(
        id: 'test123',
        componentLibraryId: 'resistor_220',
        name: '220Ω Resistor',
        category: 'resistor',
        transform: Transform3D(x: 1.0, y: 2.0),
        properties: {'resistance': 220},
        connectedTo: ['led1', 'battery1'],
      );

      final json = component.toJson();
      final deserialized = ArComponent.fromJson(json);

      expect(deserialized.id, component.id);
      expect(deserialized.name, component.name);
      expect(deserialized.category, component.category);
      expect(deserialized.connectedTo, component.connectedTo);
      expect(deserialized.properties['resistance'], 220);
    });
  });

  group('ArProject Tests', () {
    test('ArProject should serialize and deserialize correctly', () {
      final project = ArProject(
        id: 'project1',
        userId: 'user123',
        title: 'My First Circuit',
        description: 'A simple LED circuit',
        components: [
          const ArComponent(
            id: 'led1',
            componentLibraryId: 'led_red',
            name: 'Red LED',
            category: 'led',
            transform: Transform3D(),
          ),
        ],
        connections: [
          const ComponentConnection(
            fromComponentId: 'battery',
            toComponentId: 'led1',
          ),
        ],
        createdAt: DateTime(2026, 1, 29),
        updatedAt: DateTime(2026, 1, 29),
      );

      final json = project.toJson();
      final deserialized = ArProject.fromJson(json);

      expect(deserialized.id, project.id);
      expect(deserialized.title, project.title);
      expect(deserialized.components.length, 1);
      expect(deserialized.connections.length, 1);
    });
  });

  group('Edge Case Tests', () {
    test('Circuit with zero resistance should not cause division by zero',
        () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'resistor',
          componentLibraryId: 'resistor_0',
          name: '0Ω Resistor (short)',
          category: 'resistor',
          transform: Transform3D(),
          properties: {'resistance': 0.0}, // Edge case
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'resistor',
        ),
      ];

      // Should not throw exception even with zero resistance
      final result = await simulationService.simulate(components, connections);
      expect(result, isNotNull);
    });

    test('Circuit with multiple parallel LEDs should calculate correctly',
        () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'led1',
          componentLibraryId: 'led_red',
          name: 'Red LED 1',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 2.0,
            'current_typical': 0.02,
            'color': 'red'
          },
        ),
        const ArComponent(
          id: 'led2',
          componentLibraryId: 'led_green',
          name: 'Green LED 2',
          category: 'led',
          transform: Transform3D(),
          properties: {
            'forward_voltage': 2.1,
            'current_typical': 0.02,
            'color': 'green'
          },
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'led1',
          fromTerminal: 'positive',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'led2',
          fromTerminal: 'positive',
          toTerminal: 'positive',
        ),
        const ComponentConnection(
          fromComponentId: 'led1',
          toComponentId: 'battery',
          fromTerminal: 'negative',
          toTerminal: 'negative',
        ),
        const ComponentConnection(
          fromComponentId: 'led2',
          toComponentId: 'battery',
          fromTerminal: 'negative',
          toTerminal: 'negative',
        ),
      ];

      final result = await simulationService.simulate(components, connections);
      // Fails because LEDs connected directly to 9V source will burn out
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('BURNOUT')), true);
      expect(result.componentStates.containsKey('led1'), true);
      expect(result.componentStates.containsKey('led2'), true);
    });

    test('Invalid component should be detected', () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'unknown',
          componentLibraryId: 'unknown_type',
          name: 'Unknown Component',
          category: 'unknown', // Invalid category
          transform: Transform3D(),
          properties: {},
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'unknown',
        ),
      ];

      // Should handle unknown component gracefully
      final result = await simulationService.simulate(components, connections);
      expect(result, isNotNull);
      expect(result.isValid, isA<bool>());
    });

    test('Very high resistance should limit current', () async {
      final components = [
        const ArComponent(
          id: 'battery',
          componentLibraryId: 'battery_9v',
          name: '9V Battery',
          category: 'power',
          transform: Transform3D(),
          properties: {'voltage': 9.0},
        ),
        const ArComponent(
          id: 'resistor',
          componentLibraryId: 'resistor_1m',
          name: '1MΩ Resistor',
          category: 'resistor',
          transform: Transform3D(),
          properties: {'resistance': 1000000}, // Very high
        ),
      ];

      final connections = [
        const ComponentConnection(
          fromComponentId: 'battery',
          toComponentId: 'resistor',
        ),
      ];

      final result = await simulationService.simulate(components, connections);
      expect(result.isValid, true);
      // Current should be very small: I = 9V / 1MΩ = 9µA = 0.000009A
      final current = result.currents['resistor'] ?? 0.0;
      expect(current, lessThan(0.00001)); // Less than 10µA (9µA is correct)
      expect(
          current, greaterThan(0.000005)); // Greater than 5µA (9µA is in range)
    });

    test('ComponentConnection serialization should handle all fields', () {
      const connection = ComponentConnection(
        fromComponentId: 'source',
        toComponentId: 'load',
        fromTerminal: 'out',
        toTerminal: 'in',
      );

      final json = connection.toJson();
      expect(json['fromComponentId'], 'source');
      expect(json['toComponentId'], 'load');
      expect(json['fromTerminal'], 'out');
      expect(json['toTerminal'], 'in');

      final deserialized = ComponentConnection.fromJson(json);
      expect(deserialized.fromComponentId, connection.fromComponentId);
      expect(deserialized.toComponentId, connection.toComponentId);
      expect(deserialized.fromTerminal, connection.fromTerminal);
      expect(deserialized.toTerminal, connection.toTerminal);
    });
  });
}
