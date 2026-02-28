import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Represents a region or continent on the world map.
class MapRegion {
  /// The unique identifier for the region.
  final String id;

  /// The display name of the region.
  final String name;

  /// The base color of the region on the map.
  final Color baseColor;

  /// A list of offsets defining the simplified polygon of the region.
  final List<Offset> points;

  /// The position for the region label.
  final Offset labelPos;

  /// A description of the region.
  final String description;

  /// Creates a [MapRegion] instance.
  MapRegion({
    required this.id,
    required this.name,
    required this.baseColor,
    required this.points,
    required this.labelPos,
    required this.description,
  });
}

/// A custom painter for rendering a simplified interactive world map with selectable regions.
class WorldMapPainter extends CustomPainter {
  /// The list of map regions to render.
  final List<MapRegion> regions;

  /// The ID of the currently selected region, if any.
  final String? selectedId;

  /// Creates a [WorldMapPainter] instance.
  WorldMapPainter({required this.regions, this.selectedId});

  @override
  void paint(Canvas canvas, Size size) {
    // Background (Ocean)

    // Paint continents
    for (var region in regions) {
      final isSelected = region.id == selectedId;
      final paint = Paint()
        ..color = isSelected
            ? region.baseColor
            : region.baseColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final path = Path();
      if (region.points.isNotEmpty) {
        path.moveTo(region.points[0].dx * size.width,
            region.points[0].dy * size.height);
        for (int i = 1; i < region.points.length; i++) {
          path.lineTo(region.points[i].dx * size.width,
              region.points[i].dy * size.height);
        }
        path.close();
      }

      // Drop shadow for selected
      if (isSelected) {
        canvas.drawShadow(path, Colors.black, 4.0, true);
      }

      canvas.drawPath(path, paint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 1;
      canvas.drawPath(path, borderPaint);

      // Label
      /*
      final textSpan = TextSpan(
        text: region.name,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: isSelected ? 14 : 10, 
          fontWeight: FontWeight.bold,
          shadows: [const Shadow(blurRadius: 2, color: Colors.black)],
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(
        region.labelPos.dx * size.width - tp.width / 2,
        region.labelPos.dy * size.height - tp.height / 2
      ));
      */
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId;
  }
}

/// A screen that displays an interactive world map simulation with selectable continents.
class WorldMapSimulation extends StatefulWidget {
  /// Creates a [WorldMapSimulation] instance.
  const WorldMapSimulation({super.key});

  @override
  State<WorldMapSimulation> createState() => _WorldMapSimulationState();
}

class _WorldMapSimulationState extends State<WorldMapSimulation> {
  final TransformationController _transformController =
      TransformationController();
  String? _selectedRegionId;

  // Simplified World Map Data (Approximations)
  final List<MapRegion> _regions = [
    MapRegion(
      id: 'na',
      name: 'North America',
      baseColor: Colors.blueAccent,
      points: [
        const Offset(0.1, 0.1),
        const Offset(0.3, 0.1),
        const Offset(0.25, 0.35),
        const Offset(0.15, 0.3)
      ],
      labelPos: const Offset(0.2, 0.2),
      description:
          'Diverse climates ranging from Arctic tundra to tropical rainforests.',
    ),
    MapRegion(
      id: 'sa',
      name: 'South America',
      baseColor: Colors.green,
      points: [
        const Offset(0.25, 0.4),
        const Offset(0.35, 0.4),
        const Offset(0.3, 0.65)
      ],
      labelPos: const Offset(0.3, 0.5),
      description: 'Home to the Amazon Rainforest and the Andes Mountains.',
    ),
    MapRegion(
      id: 'eu',
      name: 'Europe',
      baseColor: Colors.purpleAccent,
      points: [
        const Offset(0.45, 0.15),
        const Offset(0.55, 0.15),
        const Offset(0.52, 0.25),
        const Offset(0.45, 0.25)
      ],
      labelPos: const Offset(0.5, 0.2),
      description:
          'A peninsula of peninsulas with key historical significance.',
    ),
    MapRegion(
      id: 'af',
      name: 'Africa',
      baseColor: Colors.orangeAccent,
      points: [
        const Offset(0.45, 0.3),
        const Offset(0.6, 0.3),
        const Offset(0.55, 0.6),
        const Offset(0.48, 0.5)
      ],
      labelPos: const Offset(0.52, 0.45),
      description:
          'Second largest continent, known for the Sahara and savannahs.',
    ),
    MapRegion(
      id: 'as',
      name: 'Asia',
      baseColor: Colors.redAccent,
      points: [
        const Offset(0.58, 0.1),
        const Offset(0.85, 0.1),
        const Offset(0.8, 0.45),
        const Offset(0.6, 0.3)
      ],
      labelPos: const Offset(0.7, 0.25),
      description:
          'Largest continent with the highest peaks and populous nations.',
    ),
    MapRegion(
      id: 'au',
      name: 'Australia',
      baseColor: Colors.amber,
      points: [
        const Offset(0.75, 0.65),
        const Offset(0.9, 0.65),
        const Offset(0.85, 0.8),
        const Offset(0.75, 0.75)
      ],
      labelPos: const Offset(0.82, 0.72),
      description: 'Newest continent geologically, unique flora and fauna.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedRegion = _regions.firstWhere(
      (r) => r.id == _selectedRegionId,
      orElse: () => _regions.first, // Default
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Interactive World Map', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            onPressed: () {
              _transformController.value = Matrix4.identity();
              setState(() => _selectedRegionId = null);
            },
          ),
        ],
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            // Map Layer
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: GestureDetector(
                onTapUp: (details) {
                  // Hit testing logic for custom painter is complex
                  // For now, toggle regions cyclically or use buttons
                },
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: CustomPaint(
                    painter: WorldMapPainter(
                      regions: _regions,
                      selectedId: _selectedRegionId,
                    ),
                  ),
                ),
              ),
            ),

            // Region Selector (Bottom Sheet style)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRegionId == null
                          ? 'Select a Region'
                          : selectedRegion.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedRegionId == null
                          ? 'Tap the buttons below to explore continents.'
                          : selectedRegion.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _regions.map((region) {
                          final isSelected = _selectedRegionId == region.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: Text(region.name),
                              backgroundColor: isSelected
                                  ? region.baseColor
                                  : Colors.white10,
                              labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70),
                              onPressed: () => _onRegionTap(region.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRegionTap(String id) {
    setState(() {
      _selectedRegionId = id;
    });

    // Phase 2: Persist Region Selection
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        Supabase.instance.client.from('user_simulation_results').insert({
          'user_id': userId,
          'sim_id': 'world_map',
          'parameters': {'action': 'select_region'},
          'results': {'region_id': id},
        }).then((_) => debugPrint('World map region selection saved'));
      }
    } catch (e) {
      debugPrint('Error persisting world map selection: $e');
    }
  }
}
