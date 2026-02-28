import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A screen that provides an interactive historical atlas with timelines and trade routes.
class HistoricalAtlasScreen extends StatefulWidget {
  /// Creates a [HistoricalAtlasScreen] instance.
  const HistoricalAtlasScreen({super.key});

  @override
  State<HistoricalAtlasScreen> createState() => _HistoricalAtlasScreenState();
}

/// Represents a specific historical event within the atlas.
class HistoricalEvent {
  /// The year of the event (negative for BCE).
  final int year;

  /// The title of the event.
  final String title;

  /// A brief description of the event.
  final String description;

  /// The region where the event occurred.
  final HistRegion region;

  /// Creates a [HistoricalEvent] instance.
  HistoricalEvent({
    required this.year,
    required this.title,
    required this.description,
    required this.region,
  });
}

/// Regions available for display in the historical atlas.
enum HistRegion {
  /// The Indian subcontinent.
  india,

  /// General Asian region.
  asia,

  /// The city and immediate surroundings of ancient Rome.
  rome,

  /// The European continent.
  europe,

  /// The Italian peninsula.
  italy,

  /// Ancient Egyptian territories.
  egypt,

  /// Ancient Greek city-states and territories.
  greece,

  /// The Persian Empire regions.
  persia,

  /// The land between the Tigris and Euphrates rivers.
  mesopotamia,

  /// The American continents.
  americas
}

/// A custom painter for rendering historical maps and trade routes.
class MapPainter extends CustomPainter {
  /// The region to display on the map.
  final HistRegion region;

  /// The list of trade routes to render.
  final List<TradeRoute> routes;

  /// The current flow percentage for route animation.
  final double? flowPercent;

  /// Creates a [MapPainter] instance.
  MapPainter({required this.region, required this.routes, this.flowPercent});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw "Old Map" background (Simplified stylized lines)
    final paint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Drawing fake topography / paper texture lines
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.5), (i + 1) * 30, paint);
    }

    // Draw Routes
    for (var route in routes) {
      final routePaint = Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (route.points.isNotEmpty) {
        path.moveTo(
            route.points[0].dx * size.width, route.points[0].dy * size.height);
        for (int i = 1; i < route.points.length; i++) {
          path.lineTo(route.points[i].dx * size.width,
              route.points[i].dy * size.height);
        }
      }

      // Dashed path effect simulation
      canvas.drawPath(path, routePaint);

      // Label for route
      if (route.points.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
              text: route.name,
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
            canvas,
            Offset(route.points[0].dx * size.width,
                route.points[0].dy * size.height - 15));
      }
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) => oldDelegate.region != region;
}

/// Represents a historical trade route.
class TradeRoute {
  /// The name of the trade route (e.g., 'Silk Road').
  final String name;

  /// A list of normalized offsets representing the route's path.
  final List<Offset> points;

  /// The region associated with the trade route.
  final HistRegion region;

  /// Creates a [TradeRoute] instance.
  TradeRoute({required this.name, required this.points, required this.region});
}

class _HistoricalAtlasScreenState extends State<HistoricalAtlasScreen>
    with SingleTickerProviderStateMixin {
  HistRegion _selectedRegion = HistRegion.india;
  final ScrollController _timelineController = ScrollController();
  late AnimationController _flowController;
  bool _isSimulating = false;

  final List<HistoricalEvent> _events = [
    // India
    HistoricalEvent(
        year: -3300,
        title: 'Indus Valley',
        description: 'Early urban civilization on the Indus river.',
        region: HistRegion.india),
    HistoricalEvent(
        year: -322,
        title: 'Maurya Empire',
        description: 'Chandragupta Maurya unifies most of India.',
        region: HistRegion.india),
    HistoricalEvent(
        year: 319,
        title: 'Gupta Empire',
        description: 'Golden Age of India; advances in science and math.',
        region: HistRegion.india),
    HistoricalEvent(
        year: 1526,
        title: 'Mughal Empire',
        description: 'Babur establishes the Mughal dynasty.',
        region: HistRegion.india),

    // Asia
    HistoricalEvent(
        year: -206,
        title: 'Han Dynasty',
        description: 'Silk Road expansion and Confucianism.',
        region: HistRegion.asia),
    HistoricalEvent(
        year: 1206,
        title: 'Mongol Empire',
        description: 'Genghis Khan begins world conquests.',
        region: HistRegion.asia),
    HistoricalEvent(
        year: 1405,
        title: 'Ming Voyages',
        description: 'Zheng He leads massive naval expeditions.',
        region: HistRegion.asia),

    // Rome & Italy
    HistoricalEvent(
        year: -753,
        title: 'Founding of Rome',
        description: 'Traditional date of Rome\'s foundation.',
        region: HistRegion.rome),
    HistoricalEvent(
        year: -509,
        title: 'Roman Republic',
        description: 'Overthrow of the Roman Monarchy.',
        region: HistRegion.rome),
    HistoricalEvent(
        year: 27,
        title: 'Roman Empire',
        description: 'Augustus becomes the first Emperor.',
        region: HistRegion.rome),
    HistoricalEvent(
        year: 476,
        title: 'Fall of Rome',
        description: 'End of the Western Roman Empire.',
        region: HistRegion.rome),
    HistoricalEvent(
        year: 1300,
        title: 'Renaissance',
        description: 'Cultural rebirth starting in Florence, Italy.',
        region: HistRegion.italy),

    // Europe
    HistoricalEvent(
        year: 800,
        title: 'Charlemagne',
        description: 'Crowned Holy Roman Emperor.',
        region: HistRegion.europe),
    HistoricalEvent(
        year: 1066,
        title: 'Norman Conquest',
        description: 'Battle of Hastings change England.',
        region: HistRegion.europe),
    HistoricalEvent(
        year: 1789,
        title: 'French Revolution',
        description: 'End of monarchy in France.',
        region: HistRegion.europe),

    // Egypt
    HistoricalEvent(
        year: -3100,
        title: 'Unification',
        description: 'Narmer unifies Upper and Lower Egypt.',
        region: HistRegion.egypt),
    HistoricalEvent(
        year: -2560,
        title: 'Great Pyramid',
        description: 'Completion of the Great Pyramid of Giza.',
        region: HistRegion.egypt),
    HistoricalEvent(
        year: -1274,
        title: 'Battle of Kadesh',
        description: 'Ramesses II fights the Hittites.',
        region: HistRegion.egypt),

    // Greece
    HistoricalEvent(
        year: -776,
        title: 'First Olympics',
        description: 'First recorded Olympic Games in Olympia.',
        region: HistRegion.greece),
    HistoricalEvent(
        year: -490,
        title: 'Battle of Marathon',
        description: 'Athens defeats the first Persian invasion.',
        region: HistRegion.greece),
    HistoricalEvent(
        year: -323,
        title: 'Alexander Dies',
        description: 'Death of Alexander the Great in Babylon.',
        region: HistRegion.greece),

    // Persia
    HistoricalEvent(
        year: -550,
        title: 'Achaemenid Empire',
        description: 'Cyrus the Great founds the First Persian Empire.',
        region: HistRegion.persia),
    HistoricalEvent(
        year: -330,
        title: 'Fall of Persia',
        description: 'Alexander the Great conquers Persepolis.',
        region: HistRegion.persia),

    // Mesopotamia
    HistoricalEvent(
        year: -3500,
        title: 'Invention of Writing',
        description: 'Sumerians develop cuneiform script.',
        region: HistRegion.mesopotamia),
    HistoricalEvent(
        year: -1754,
        title: 'Code of Hammurabi',
        description: 'Babylonian law code established.',
        region: HistRegion.mesopotamia),

    // Americas
    HistoricalEvent(
        year: 250,
        title: 'Classic Maya',
        description: 'Peak of Maya civilization and urbanization.',
        region: HistRegion.americas),
    HistoricalEvent(
        year: 1428,
        title: 'Aztec Empire',
        description: 'Formation of the Triple Alliance.',
        region: HistRegion.americas),
    HistoricalEvent(
        year: 1438,
        title: 'Inca Empire',
        description: 'Pachacuti begins expansion of Tawantinsuyu.',
        region: HistRegion.americas),
  ];

  final List<TradeRoute> _routes = [
    TradeRoute(
      name: 'Spice Trade',
      region: HistRegion.india,
      points: [
        const Offset(0.2, 0.8),
        const Offset(0.4, 0.7),
        const Offset(0.6, 0.75),
        const Offset(0.8, 0.6)
      ],
    ),
    TradeRoute(
      name: 'Silk Road',
      region: HistRegion.asia,
      points: [
        const Offset(0.1, 0.5),
        const Offset(0.3, 0.45),
        const Offset(0.5, 0.5),
        const Offset(0.7, 0.4),
        const Offset(0.9, 0.45)
      ],
    ),
    TradeRoute(
      name: 'Roman Merchant Route',
      region: HistRegion.rome,
      points: [
        const Offset(0.3, 0.6),
        const Offset(0.5, 0.5),
        const Offset(0.7, 0.6)
      ],
    ),
    TradeRoute(
      name: 'Nile Trade',
      region: HistRegion.egypt,
      points: [
        const Offset(0.5, 0.1),
        const Offset(0.5, 0.9),
      ],
    ),
    TradeRoute(
      name: 'Aegean Sea Trade',
      region: HistRegion.greece,
      points: [
        const Offset(0.3, 0.3),
        const Offset(0.6, 0.4),
        const Offset(0.4, 0.6),
      ],
    ),
    TradeRoute(
      name: 'Royal Road',
      region: HistRegion.persia,
      points: [
        const Offset(0.1, 0.4),
        const Offset(0.9, 0.4),
      ],
    ),
    TradeRoute(
      name: 'Tigris-Euphrates',
      region: HistRegion.mesopotamia,
      points: [
        const Offset(0.4, 0.2),
        const Offset(0.6, 0.8),
      ],
    ),
    TradeRoute(
      name: 'Inca Roads',
      region: HistRegion.americas,
      points: [
        const Offset(0.2, 0.2),
        const Offset(0.2, 0.8),
      ],
    ),
  ];

  List<HistoricalEvent> get _filteredEvents => _events
      .where((e) =>
          e.region == _selectedRegion ||
          (_selectedRegion == HistRegion.rome && e.region == HistRegion.italy))
      .toList()
    ..sort((a, b) => a.year.compareTo(b.year));

  List<TradeRoute> get _filteredRoutes =>
      _routes.where((r) => r.region == _selectedRegion).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Historical Atlas'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),

            // Region Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: HistRegion.values.map((region) {
                  final bool isSelected = _selectedRegion == region;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(region.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (val) =>
                          setState(() => _selectedRegion = region),
                      selectedColor: Colors.amber.withValues(alpha: 0.3),
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.amber : Colors.white70),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Map / Route Visualizer
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _flowController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: MapPainter(
                                region: _selectedRegion,
                                routes: _filteredRoutes,
                                flowPercent: _isSimulating
                                    ? _flowController.value
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Geographic Snapshot',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                            Text(_selectedRegion.name.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: FloatingActionButton.small(
                          onPressed: _toggleSimulation,
                          backgroundColor:
                              _isSimulating ? Colors.orange : Colors.white10,
                          child: Icon(
                              _isSimulating ? Icons.stop : Icons.play_arrow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Timeline
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Chronological Timeline',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _timelineController,
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle),
                                  ),
                                  if (index < _filteredEvents.length - 1)
                                    Container(
                                        width: 2,
                                        height: 60,
                                        color: Colors.white24),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.year < 0
                                              ? '${event.year.abs()} BCE'
                                              : '${event.year} CE',
                                          style: const TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        Text(event.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(event.description,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  void _toggleSimulation() {
    setState(() {
      _isSimulating = !_isSimulating;
      if (_isSimulating) {
        _flowController.repeat();
      } else {
        _flowController.stop();
      }
    });
  }
}
