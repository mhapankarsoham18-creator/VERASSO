import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A screen for comparing different biomes and their ecospheric characteristics.
class EcoSphereComparisonScreen extends StatefulWidget {
  /// Creates an [EcoSphereComparisonScreen] instance.
  const EcoSphereComparisonScreen({super.key});

  @override
  State<EcoSphereComparisonScreen> createState() =>
      _EcoSphereComparisonScreenState();
}

class _BiomeData {
  final String name;
  final Color color;
  final String temp;
  final String rainfall;
  final String vegetation;
  final String fauna;
  final String description;
  final Color skyTop;
  final Color skyBottom;
  final Color terrain;
  final Color terrainDark;
  final IconData weatherIcon;

  _BiomeData({
    required this.name,
    required this.color,
    required this.temp,
    required this.rainfall,
    required this.vegetation,
    required this.fauna,
    required this.description,
    required this.skyTop,
    required this.skyBottom,
    required this.terrain,
    required this.terrainDark,
    required this.weatherIcon,
  });
}

class _BiomePainter extends CustomPainter {
  final String biomeKey;
  final _BiomeData data;
  final double animValue;

  _BiomePainter({
    required this.biomeKey,
    required this.data,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSkyAndAtmosphere(canvas, size);
    _drawTerrain(canvas, size);
    _drawEnvironmentalEffects(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _BiomePainter oldDelegate) =>
      oldDelegate.biomeKey != biomeKey || oldDelegate.animValue != animValue;

  void _drawCactus(Canvas canvas, Offset bottom, double height, Paint paint) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bottom.dx - 4, bottom.dy - height, 8, height),
            const Radius.circular(4)),
        paint);
    // Arms
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bottom.dx - 12, bottom.dy - height * 0.7, 8, 4),
            const Radius.circular(2)),
        paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bottom.dx + 4, bottom.dy - height * 0.5, 8, 4),
            const Radius.circular(2)),
        paint);
  }

  void _drawEnvironmentalEffects(Canvas canvas, Size size) {
    final Random random = Random(123);
    final Paint effectPaint = Paint()..strokeCap = StrokeCap.round;

    if (biomeKey == 'Rainforest') {
      effectPaint.color = Colors.white.withValues(alpha: 0.3);
      effectPaint.strokeWidth = 1.0;
      for (int i = 0; i < 40; i++) {
        double x = random.nextDouble() * size.width;
        double y = ((random.nextDouble() + animValue) % 1.0) * size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 2, y + 8), effectPaint);
      }
    } else if (biomeKey == 'Tundra') {
      effectPaint.color = Colors.white.withValues(alpha: 0.6);
      for (int i = 0; i < 30; i++) {
        double x = (random.nextDouble() * size.width +
                sin(animValue * 2 * pi + i) * 10) %
            size.width;
        double y =
            ((random.nextDouble() + animValue * 0.5) % 1.0) * size.height;
        canvas.drawCircle(Offset(x, y), 1.5, effectPaint);
      }
    } else if (biomeKey == 'Desert') {
      // Heat waves or shimmering particles
      effectPaint.color = Colors.white.withValues(alpha: 0.1);
      for (int i = 0; i < 15; i++) {
        double x = random.nextDouble() * size.width;
        double y = random.nextDouble() * size.height;
        double s = 2 + sin(animValue * pi * 2 + i) * 2;
        canvas.drawCircle(Offset(x, y), s, effectPaint);
      }
    } else if (biomeKey == 'Savannah') {
      // Wind lines
      effectPaint.color = Colors.white.withValues(alpha: 0.1);
      effectPaint.strokeWidth = 0.5;
      for (int i = 0; i < 10; i++) {
        double x = ((random.nextDouble() + animValue) % 1.0) * size.width;
        double y = random.nextDouble() * size.height;
        canvas.drawLine(Offset(x, y), Offset(x + 30, y), effectPaint);
      }
    }
  }

  void _drawSkyAndAtmosphere(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [data.skyTop, data.skyBottom],
      ).createShader(rect);

    canvas.drawRect(rect, skyPaint);

    // Draw a subtle sun/moon glow
    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1);

    if (biomeKey == 'Desert' || biomeKey == 'Savannah') {
      canvas.drawCircle(
          Offset(size.width * 0.7, size.height * 0.3), 40, glowPaint);
      glowPaint.color = Colors.white.withValues(alpha: 0.05);
      canvas.drawCircle(
          Offset(size.width * 0.7, size.height * 0.3), 70, glowPaint);
    }
  }

  void _drawTerrain(Canvas canvas, Size size) {
    final double terrainBase = size.height * 0.7;

    // Draw back hills
    final Paint darkTerrainPaint = Paint()..color = data.terrainDark;

    final Path backHills = Path();
    backHills.moveTo(0, size.height);
    backHills.lineTo(0, terrainBase - 10);

    if (biomeKey == 'Desert') {
      backHills.quadraticBezierTo(size.width * 0.25, terrainBase - 40,
          size.width * 0.5, terrainBase - 20);
      backHills.quadraticBezierTo(
          size.width * 0.75, terrainBase, size.width, terrainBase - 30);
    } else {
      backHills.quadraticBezierTo(size.width * 0.3, terrainBase - 20,
          size.width * 0.6, terrainBase - 10);
      backHills.quadraticBezierTo(
          size.width * 0.8, terrainBase - 30, size.width, terrainBase - 15);
    }

    backHills.lineTo(size.width, size.height);
    backHills.close();
    canvas.drawPath(backHills, darkTerrainPaint);

    // Draw front terrain
    final Paint terrainPaint = Paint()..color = data.terrain;
    final Path frontPath = Path();
    frontPath.moveTo(0, size.height);
    frontPath.lineTo(0, terrainBase + 10);

    if (biomeKey == 'Desert') {
      frontPath.quadraticBezierTo(
          size.width * 0.5, terrainBase - 10, size.width, terrainBase + 20);
    } else if (biomeKey == 'Tundra') {
      frontPath.lineTo(size.width * 0.5, terrainBase + 5);
      frontPath.lineTo(size.width, terrainBase + 15);
    } else {
      frontPath.quadraticBezierTo(
          size.width * 0.5, terrainBase + 30, size.width, terrainBase + 5);
    }

    frontPath.lineTo(size.width, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, terrainPaint);

    _drawVegetation(canvas, size, terrainBase);
  }

  void _drawTree(Canvas canvas, Offset bottom, double size, Paint paint) {
    final Path path = Path();
    path.moveTo(bottom.dx, bottom.dy);
    path.lineTo(bottom.dx - size / 3, bottom.dy);
    path.lineTo(bottom.dx, bottom.dy - size);
    path.lineTo(bottom.dx + size / 3, bottom.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawUmbrellaTree(
      Canvas canvas, Offset bottom, double height, Paint paint) {
    // Trunk
    canvas.drawRect(
        Rect.fromLTWH(bottom.dx - 2, bottom.dy - height, 4, height), paint);
    // Canopy
    final Paint canopyPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bottom.dx, bottom.dy - height),
            width: height * 1.5,
            height: height * 0.4),
        canopyPaint);
  }

  void _drawVegetation(Canvas canvas, Size size, double terrainBase) {
    final Paint vegPaint = Paint()..style = PaintingStyle.fill;

    if (biomeKey == 'Rainforest') {
      vegPaint.color = Colors.green.shade900;
      for (int i = 0; i < 5; i++) {
        double x = size.width * (0.2 + i * 0.15);
        double y = terrainBase + 10;
        _drawTree(canvas, Offset(x, y), 40, vegPaint);
      }
    } else if (biomeKey == 'Desert') {
      vegPaint.color = Colors.green.shade800;
      for (int i = 0; i < 3; i++) {
        double x = size.width * (0.3 + i * 0.2);
        double y = terrainBase + 5;
        _drawCactus(canvas, Offset(x, y), 20, vegPaint);
      }
    } else if (biomeKey == 'Savannah') {
      vegPaint.color = const Color(0xFF5D4037);
      _drawUmbrellaTree(
          canvas, Offset(size.width * 0.4, terrainBase + 20), 45, vegPaint);
      _drawUmbrellaTree(
          canvas, Offset(size.width * 0.7, terrainBase + 10), 35, vegPaint);
    }
  }
}

class _EcoSphereComparisonScreenState extends State<EcoSphereComparisonScreen>
    with TickerProviderStateMixin {
  String _biomeA = 'Rainforest';
  String _biomeB = 'Desert';

  late AnimationController _animController;

  final Map<String, _BiomeData> _biomeData = {
    'Rainforest': _BiomeData(
      name: 'Tropical Rainforest',
      color: Colors.green,
      temp: '25-30°C',
      rainfall: '2000+ mm',
      vegetation: 'High (Liana, Canopy)',
      fauna: 'Jaguar, Toucan',
      description: 'High biodiversity and dense canopy layers.',
      skyTop: const Color(0xFF1B4332),
      skyBottom: const Color(0xFF40916C),
      terrain: const Color(0xFF2D6A4F),
      terrainDark: const Color(0xFF1B4332),
      weatherIcon: LucideIcons.cloudDrizzle,
    ),
    'Desert': _BiomeData(
      name: 'Arid Desert',
      color: Colors.orangeAccent,
      temp: '10-45°C',
      rainfall: '< 250 mm',
      vegetation: 'Low (Cactus, Scrub)',
      fauna: 'Camel, Scorpion',
      description: 'Extreme temperature fluctuations and limited water.',
      skyTop: const Color(0xFFFF8C00),
      skyBottom: const Color(0xFFFFD480),
      terrain: const Color(0xFFC4A35A),
      terrainDark: const Color(0xFF8B6914),
      weatherIcon: LucideIcons.sun,
    ),
    'Tundra': _BiomeData(
      name: 'Arctic Tundra',
      color: Colors.lightBlueAccent,
      temp: '-30-10°C',
      rainfall: '150-250 mm',
      vegetation: 'Moss, Lichen',
      fauna: 'Polar Bear, Reindeer',
      description: 'Treeless plain with permafrost subsoil.',
      skyTop: const Color(0xFFA8DADC),
      skyBottom: const Color(0xFFE8F4F8),
      terrain: const Color(0xFFD5E8EB),
      terrainDark: const Color(0xFF9BBEC8),
      weatherIcon: LucideIcons.snowflake,
    ),
    'Savannah': _BiomeData(
      name: 'Tropical Savannah',
      color: Colors.amber,
      temp: '20-30°C',
      rainfall: '500-1500 mm',
      vegetation: 'Grassland, Acacia',
      fauna: 'Lion, Elephant',
      description: 'Mixed woodland and grassland ecosystem.',
      skyTop: const Color(0xFFF7B32B),
      skyBottom: const Color(0xFFFCF6BD),
      terrain: const Color(0xFF8B7D3C),
      terrainDark: const Color(0xFF6B5B1E),
      weatherIcon: LucideIcons.wind,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('EcoSphere: Biome Comparison'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Comparison Table
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  padding: const EdgeInsets.all(0),
                  child: Row(
                    children: [
                      _buildBiomeColumn(_biomeA, isLeft: true),
                      const VerticalDivider(width: 1, color: Colors.white10),
                      _buildBiomeColumn(_biomeB, isLeft: false),
                    ],
                  ),
                ),
              ),
            ),
            // Metrics comparison
            _buildMetricGrid(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  Widget _buildBiomeColumn(String biomeKey, {required bool isLeft}) {
    final data = _biomeData[biomeKey]!;
    return Expanded(
      child: Column(
        children: [
          // Header / Dropdown
          Container(
            padding: const EdgeInsets.all(16),
            color: data.color.withValues(alpha: 0.1),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: biomeKey,
                isExpanded: true,
                dropdownColor: Colors.black87,
                items: _biomeData.keys
                    .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (isLeft) {
                        _biomeA = val;
                      } else {
                        _biomeB = val;
                      }
                    });
                  }
                },
              ),
            ),
          ),
          // Rich Biome Visualization
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: data.color.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) => CustomPaint(
                    painter: _BiomePainter(
                      biomeKey: biomeKey,
                      data: data,
                      animValue: _animController.value,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Weather icon overlay
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Icon(data.weatherIcon,
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        // Biome name badge
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(data.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(data.description,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid() {
    final dataA = _biomeData[_biomeA]!;
    final dataB = _biomeData[_biomeB]!;

    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _MetricRow(
              icon: LucideIcons.thermometer,
              label: 'Temperature',
              valA: dataA.temp,
              valB: dataB.temp),
          const Divider(color: Colors.white10),
          _MetricRow(
              icon: LucideIcons.cloudRain,
              label: 'Annual Rainfall',
              valA: dataA.rainfall,
              valB: dataB.rainfall),
          const Divider(color: Colors.white10),
          _MetricRow(
              icon: LucideIcons.layers,
              label: 'Vegetation',
              valA: dataA.vegetation,
              valB: dataB.vegetation),
          const Divider(color: Colors.white10),
          _MetricRow(
              icon: LucideIcons.dog,
              label: 'Key Fauna',
              valA: dataA.fauna,
              valB: dataB.fauna),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valA;
  final String valB;

  const _MetricRow(
      {required this.icon,
      required this.label,
      required this.valA,
      required this.valB});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const Spacer(),
          Text(valA,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Text('vs',
              style: TextStyle(fontSize: 10, color: Colors.white24)),
          const SizedBox(width: 8),
          Text(valB,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
