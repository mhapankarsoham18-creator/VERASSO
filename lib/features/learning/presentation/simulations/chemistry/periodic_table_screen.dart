import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Represents the data for a chemical element in the periodic table.
class ElementData {
  /// The atomic number of the element.
  final int number;

  /// The chemical symbol of the element.
  final String symbol;

  /// The name of the element.
  final String name;

  /// The category of the element (e.g., Alkali Metal).
  final String category;

  /// The color associated with the element's category.
  final Color color;

  /// The atomic mass of the element.
  final String mass;

  /// The boiling point of the element.
  final String boilingPt;

  /// The density of the element.
  final String density;

  /// The year or era of discovery.
  final String discovery;

  /// The number of electrons in each electron shell.
  final List<int> shells;

  /// Creates an [ElementData] instance.
  ElementData({
    required this.number,
    required this.symbol,
    required this.name,
    required this.category,
    required this.color,
    required this.mass,
    required this.boilingPt,
    required this.density,
    required this.discovery,
    required this.shells,
  });
}

/// A screen that displays an interactive periodic table of elements.
class PeriodicTableScreen extends StatefulWidget {
  /// Creates a [PeriodicTableScreen] instance.
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _BohrModelPainter extends CustomPainter {
  final ElementData element;
  _BohrModelPainter(this.element);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = element.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw Nucleus
    canvas.drawCircle(center, 8, Paint()..color = element.color);

    // Draw Shells and Electrons
    for (int i = 0; i < element.shells.length; i++) {
      final radius = 20.0 + (i * 15.0);
      canvas.drawCircle(center, radius, paint);

      final electrons = element.shells[i];
      for (int j = 0; j < electrons; j++) {
        final angle = (j / electrons) * 2 * math.pi;
        final electronPos = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        canvas.drawCircle(electronPos, 3, Paint()..color = element.color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  ElementData? _selectedElement;

  final List<ElementData> _elements = [
    ElementData(
        number: 1,
        symbol: 'H',
        name: 'Hydrogen',
        category: 'Non-metal',
        color: Colors.blueAccent,
        mass: '1.008',
        boilingPt: '-252.87 °C',
        density: '0.089 g/L',
        discovery: '1766',
        shells: [1]),
    ElementData(
        number: 2,
        symbol: 'He',
        name: 'Helium',
        category: 'Noble Gas',
        color: Colors.purpleAccent,
        mass: '4.0026',
        boilingPt: '-268.93 °C',
        density: '0.178 g/L',
        discovery: '1868',
        shells: [2]),
    ElementData(
        number: 3,
        symbol: 'Li',
        name: 'Lithium',
        category: 'Alkali Metal',
        color: Colors.redAccent,
        mass: '6.94',
        boilingPt: '1342 °C',
        density: '0.534 g/cm³',
        discovery: '1817',
        shells: [2, 1]),
    ElementData(
        number: 4,
        symbol: 'Be',
        name: 'Beryllium',
        category: 'Alkaline Earth',
        color: Colors.orangeAccent,
        mass: '9.0122',
        boilingPt: '2470 °C',
        density: '1.85 g/cm³',
        discovery: '1798',
        shells: [2, 2]),
    ElementData(
        number: 5,
        symbol: 'B',
        name: 'Boron',
        category: 'Metalloid',
        color: Colors.greenAccent,
        mass: '10.81',
        boilingPt: '3927 °C',
        density: '2.34 g/cm³',
        discovery: '1808',
        shells: [2, 3]),
    ElementData(
        number: 6,
        symbol: 'C',
        name: 'Carbon',
        category: 'Non-metal',
        color: Colors.blueAccent,
        mass: '12.011',
        boilingPt: '4827 °C',
        density: '2.267 g/cm³',
        discovery: 'Ancient',
        shells: [2, 4]),
    ElementData(
        number: 7,
        symbol: 'N',
        name: 'Nitrogen',
        category: 'Non-metal',
        color: Colors.blueAccent,
        mass: '14.007',
        boilingPt: '-195.79 °C',
        density: '1.250 g/L',
        discovery: '1772',
        shells: [2, 5]),
    ElementData(
        number: 8,
        symbol: 'O',
        name: 'Oxygen',
        category: 'Non-metal',
        color: Colors.blueAccent,
        mass: '15.999',
        boilingPt: '-182.95 °C',
        density: '1.429 g/L',
        discovery: '1774',
        shells: [2, 6]),
    ElementData(
        number: 9,
        symbol: 'F',
        name: 'Fluorine',
        category: 'Halogen',
        color: Colors.tealAccent,
        mass: '18.998',
        boilingPt: '-188.12 °C',
        density: '1.696 g/L',
        discovery: '1886',
        shells: [2, 7]),
    ElementData(
        number: 10,
        symbol: 'Ne',
        name: 'Neon',
        category: 'Noble Gas',
        color: Colors.purpleAccent,
        mass: '20.180',
        boilingPt: '-246.08 °C',
        density: '0.899 g/L',
        discovery: '1898',
        shells: [2, 8]),
    ElementData(
        number: 11,
        symbol: 'Na',
        name: 'Sodium',
        category: 'Alkali Metal',
        color: Colors.redAccent,
        mass: '22.990',
        boilingPt: '883 °C',
        density: '0.971 g/cm³',
        discovery: '1807',
        shells: [2, 8, 1]),
    ElementData(
        number: 12,
        symbol: 'Mg',
        name: 'Magnesium',
        category: 'Alkaline Earth',
        color: Colors.orangeAccent,
        mass: '24.305',
        boilingPt: '1090 °C',
        density: '1.738 g/cm³',
        discovery: '1755',
        shells: [2, 8, 2]),
    ElementData(
        number: 13,
        symbol: 'Al',
        name: 'Aluminum',
        category: 'Post-transition',
        color: Colors.grey,
        mass: '26.982',
        boilingPt: '2470 °C',
        density: '2.70 g/cm³',
        discovery: '1825',
        shells: [2, 8, 3]),
    ElementData(
        number: 14,
        symbol: 'Si',
        name: 'Silicon',
        category: 'Metalloid',
        color: Colors.greenAccent,
        mass: '28.085',
        boilingPt: '3265 °C',
        density: '2.329 g/cm³',
        discovery: '1824',
        shells: [2, 8, 4]),
    ElementData(
        number: 15,
        symbol: 'P',
        name: 'Phosphorus',
        category: 'Non-metal',
        color: Colors.blueAccent,
        mass: '30.974',
        boilingPt: '280.5 °C',
        density: '1.823 g/cm³',
        discovery: '1669',
        shells: [2, 8, 5]),
    ElementData(
        number: 16,
        symbol: 'S',
        name: 'Sulfur',
        category: 'Non-metal',
        color: Colors.blueAccent,
        mass: '32.06',
        boilingPt: '444.6 °C',
        density: '2.07 g/cm³',
        discovery: 'Ancient',
        shells: [2, 8, 6]),
    ElementData(
        number: 17,
        symbol: 'Cl',
        name: 'Chlorine',
        category: 'Halogen',
        color: Colors.tealAccent,
        mass: '35.45',
        boilingPt: '-34.04 °C',
        density: '3.2 g/L',
        discovery: '1774',
        shells: [2, 8, 7]),
    ElementData(
        number: 18,
        symbol: 'Ar',
        name: 'Argon',
        category: 'Noble Gas',
        color: Colors.purpleAccent,
        mass: '39.948',
        boilingPt: '-185.85 °C',
        density: '1.784 g/L',
        discovery: '1894',
        shells: [2, 8, 8]),
    ElementData(
        number: 19,
        symbol: 'K',
        name: 'Potassium',
        category: 'Alkali Metal',
        color: Colors.redAccent,
        mass: '39.098',
        boilingPt: '759 °C',
        density: '0.89 g/cm³',
        discovery: '1807',
        shells: [2, 8, 8, 1]),
    ElementData(
        number: 20,
        symbol: 'Ca',
        name: 'Calcium',
        category: 'Alkaline Earth',
        color: Colors.orangeAccent,
        mass: '40.078',
        boilingPt: '1484 °C',
        density: '1.54 g/cm³',
        discovery: '1808',
        shells: [2, 8, 8, 2]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Periodic Table'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: _elements.length,
                    itemBuilder: (context, index) {
                      final element = _elements[index];
                      return _buildElementCard(element);
                    },
                  ),
                ),
              ),
              if (_selectedElement != null) _buildDetailPane(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBohrModel(ElementData element) {
    return CustomPaint(
      painter: _BohrModelPainter(element),
      size: Size.infinite,
    );
  }

  Widget _buildDetailPane() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border:
            Border.all(color: _selectedElement!.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _selectedElement!.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _selectedElement!.color),
                ),
                alignment: Alignment.center,
                child: Text(_selectedElement!.symbol,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _selectedElement!.color)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedElement!.name,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    Text(_selectedElement!.category,
                        style: TextStyle(
                            color: _selectedElement!.color,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Atomic Mass',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text(_selectedElement!.mass,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 120,
                    child: _buildBohrModel(_selectedElement!),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(LucideIcons.thermometer, 'Boiling Pt',
                          _selectedElement!.boilingPt),
                      _buildStatItem(LucideIcons.droplets, 'Density',
                          _selectedElement!.density),
                      _buildStatItem(LucideIcons.info, 'Discovery',
                          _selectedElement!.discovery),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn().slideY(
        begin: 1.0, end: 0.0, curve: Curves.easeOutBack, duration: 400.ms);
  }

  Widget _buildElementCard(ElementData element) {
    final isSelected = _selectedElement?.number == element.number;

    return GestureDetector(
      onTap: () => setState(() => _selectedElement = element),
      child: GlassContainer(
        padding: const EdgeInsets.all(4),
        border: Border.all(color: isSelected ? element.color : Colors.white10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${element.number}',
                style: const TextStyle(fontSize: 10, color: Colors.white38)),
            Text(element.symbol,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: element.color)),
            Text(element.name,
                style: const TextStyle(fontSize: 8),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 24),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
