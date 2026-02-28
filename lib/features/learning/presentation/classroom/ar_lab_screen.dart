import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'services/ar_sync_service.dart';

/// A screen that provides a shared, interactive AR laboratory for experiments.
class ArLabScreen extends ConsumerStatefulWidget {
  /// Creates an [ArLabScreen] instance.
  const ArLabScreen({super.key});

  @override
  ConsumerState<ArLabScreen> createState() => _ArLabScreenState();
}

/// Custom painter for rendering a blueprint or schematic view of a chemical reaction.
class BlueprintPainter extends CustomPainter {
  /// The current pH value to display.
  final double ph;

  /// The current temperature to display.
  final double temp;

  /// Whether the reaction is currently active.
  final bool isActive;

  /// Creates a [BlueprintPainter] instance.
  BlueprintPainter(
      {required this.ph, required this.temp, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw Beaker Blueprint
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.1)
      ..lineTo(size.width * 0.2, size.height * 0.9)
      ..lineTo(size.width * 0.8, size.height * 0.9)
      ..lineTo(size.width * 0.8, size.height * 0.1);

    canvas.drawPath(path, paint);

    // Measurement Marks
    for (int i = 1; i < 5; i++) {
      double y = size.height * 0.9 - (i * size.height * 0.2);
      canvas.drawLine(
          Offset(size.width * 0.2, y), Offset(size.width * 0.3, y), paint);
      // Labels
      final textSpan = TextSpan(
        text: '${i * 25}%',
        style: const TextStyle(
            color: Colors.blueAccent, fontSize: 8, fontFamily: 'monospace'),
      );
      final textPainter =
          TextPainter(textDirection: TextDirection.ltr, text: textSpan)
            ..layout();
      textPainter.paint(canvas, Offset(size.width * 0.05, y - 4));
    }

    // Reaction Indicator (Schematic Symbol)
    if (isActive) {
      final center = Offset(size.width * 0.5, size.height * 0.5);
      canvas.drawCircle(center, 20, paint);
      canvas.drawLine(
          center.translate(-15, -15), center.translate(15, 15), paint);
      canvas.drawLine(
          center.translate(15, -15), center.translate(-15, 15), paint);
    }

    // Labels for Parameters
    _drawLabel(canvas, size, "PH_VAL: ${ph.toStringAsFixed(1)}",
        Offset(size.width * 0.5, size.height * 0.95));
    _drawLabel(canvas, size, "TEMP: ${temp.toStringAsFixed(1)}°C",
        Offset(size.width * 0.85, size.height * 0.5),
        vertical: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _drawLabel(Canvas canvas, Size size, String text, Offset position,
      {bool vertical = false}) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold),
    );
    final textPainter =
        TextPainter(textDirection: TextDirection.ltr, text: textSpan)..layout();

    if (vertical) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(-1.5708); // 90 degrees in radians
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
      canvas.restore();
    } else {
      textPainter.paint(
          canvas, Offset(position.dx - textPainter.width / 2, position.dy));
    }
  }
}

class _ArLabScreenState extends ConsumerState<ArLabScreen> {
  bool _isBlueprintMode = false;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(arSyncServiceProvider);
    final syncService = ref.read(arSyncServiceProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("AR Shared Lab"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
                _isBlueprintMode ? LucideIcons.layers : LucideIcons.penTool),
            onPressed: () =>
                setState(() => _isBlueprintMode = !_isBlueprintMode),
            tooltip: "Toggle Blueprint Mode",
          ),
          IconButton(
            icon: const Icon(LucideIcons.info),
            onPressed: () {},
          )
        ],
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 1. Simulation View (Visual Representative)
                Expanded(
                  flex: 3,
                  child: GlassContainer(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isBlueprintMode
                              ? _buildBlueprintView(syncState)
                              : _buildVisualizer(syncState),
                          const SizedBox(height: 20),
                          Text(
                            "Last update by: ${syncState.lastUpdatedBy}",
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Control Panel
                Expanded(
                  flex: 4,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Experiment Controls",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildControlRow(
                            "Temperature (°C)",
                            syncState.parameters['temperature'],
                            0,
                            100,
                            (val) =>
                                syncService.updateParameter('temperature', val),
                          ),
                          const SizedBox(height: 16),
                          _buildControlRow(
                            "pH Level",
                            syncState.parameters['phValue'],
                            0,
                            14,
                            (val) =>
                                syncService.updateParameter('phValue', val),
                          ),
                          const SizedBox(height: 16),
                          _buildControlRow(
                            "Mixing Speed",
                            syncState.parameters['mixingSpeed'],
                            0,
                            10,
                            (val) =>
                                syncService.updateParameter('mixingSpeed', val),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Reaction Status",
                                  style: TextStyle(color: Colors.white)),
                              Switch(
                                value: syncState.parameters['isReactionActive'],
                                onChanged: (val) => syncService.updateParameter(
                                    'isReactionActive', val),
                                activeThumbColor: Colors.blueAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlueprintView(ArExperimentState state) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: BlueprintPainter(
              ph: state.parameters['phValue'],
              temp: state.parameters['temperature'],
              isActive: state.parameters['isReactionActive'],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text("TECHNICAL SCHEMATIC V1.0",
            style: TextStyle(
                color: Colors.blueAccent,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildControlRow(String label, dynamic value, double min, double max,
      Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              value is double ? value.toStringAsFixed(1) : value.toString(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: (value as num).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildVisualizer(ArExperimentState state) {
    final ph = state.parameters['phValue'] as double;
    final temp = state.parameters['temperature'] as double;
    final isActive = state.parameters['isReactionActive'] as bool;
    final speed = state.parameters['mixingSpeed'] as double;

    // Determine color based on pH
    Color liquidColor = Colors.blueAccent;
    if (ph < 6) liquidColor = Colors.redAccent;
    if (ph > 8) liquidColor = Colors.purpleAccent;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Beaker
            Container(
              width: 150,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white38, width: 3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
            // Liquid
            Positioned(
              bottom: 0,
              child: Container(
                width: 144,
                height: 120 + (temp / 2), // Level varies by temp simulator
                decoration: BoxDecoration(
                  color: liquidColor.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              )
                  .animate(target: isActive ? 1 : 0)
                  .shimmer(duration: (2000 / (speed + 1)).ms),
            ),
            // Bubbles (if active)
            if (isActive)
              ...List.generate(
                  5,
                  (i) => Positioned(
                        bottom: 20,
                        left: 40.0 + (i * 20),
                        child: const Icon(LucideIcons.circle,
                                size: 8, color: Colors.white70)
                            .animate(onPlay: (c) => c.repeat())
                            .moveY(
                                begin: 0,
                                end: -100,
                                duration: (1000 + (i * 200)).ms)
                            .fadeOut(),
                      )),
          ],
        ),
        const SizedBox(height: 10),
        const Text("Physics Simulation (Sync Active)",
            style: TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
