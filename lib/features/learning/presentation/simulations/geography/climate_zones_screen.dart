import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Represents the characteristics of a specific climate zone.
class ClimateZone {
  /// The name of the climate zone.
  final String name;

  /// The color used to represent the zone in the visualization.
  final Color color;

  /// A brief description of the climate zone.
  final String description;

  /// The average temperature range in the zone.
  final String temperatureRange;

  /// The type or amount of precipitation in the zone.
  final String precipitation;

  /// The typical flora found in the zone.
  final String flora;

  /// The typical fauna found in the zone.
  final String fauna;

  /// Creates a [ClimateZone] instance.
  ClimateZone({
    required this.name,
    required this.color,
    required this.description,
    required this.temperatureRange,
    required this.precipitation,
    required this.flora,
    required this.fauna,
  });
}

/// A screen for exploring different global climate zones and their features.
class ClimateZonesScreen extends StatefulWidget {
  /// Creates a [ClimateZonesScreen] instance.
  const ClimateZonesScreen({super.key});

  @override
  State<ClimateZonesScreen> createState() => _ClimateZonesScreenState();
}

class _ClimateZonesScreenState extends State<ClimateZonesScreen> {
  final List<ClimateZone> _zones = [
    ClimateZone(
      name: 'Polar Zone',
      color: Colors.white,
      description: 'The coldest climates on Earth, found near the poles.',
      temperatureRange: '-50°C to 10°C',
      precipitation: 'Low (Snow)',
      flora: 'Mosses, Lichens',
      fauna: 'Polar Bears, Penguins, Seals',
    ),
    ClimateZone(
      name: 'Continental Zone',
      color: Colors.blue[300]!,
      description:
          'Found in the interior of continents, with hot summers and cold winters.',
      temperatureRange: '-10°C to 25°C',
      precipitation: 'Moderate',
      flora: 'Coniferous Forests',
      fauna: 'Bears, Wolves, Deer',
    ),
    ClimateZone(
      name: 'Temperate Zone',
      color: Colors.green,
      description: 'Moderate climate, neither extremely hot nor cold.',
      temperatureRange: '0°C to 20°C',
      precipitation: 'Moderate to High',
      flora: 'Deciduous Trees, Grasses',
      fauna: 'Squirrels, Rabbits, Foxes',
    ),
    ClimateZone(
      name: 'Dry / Arid Zone',
      color: Colors.orange,
      description: 'Very little precipitation, often hot during the day.',
      temperatureRange: '10°C to 45°C',
      precipitation: 'Very Low',
      flora: 'Cacti, Succulents',
      fauna: 'Camels, Lizards, Scorpions',
    ),
    ClimateZone(
      name: 'Tropical Zone',
      color: Colors.redAccent,
      description: 'Hot and humid year-round, found near the equator.',
      temperatureRange: '20°C to 35°C',
      precipitation: 'High (Rainforests)',
      flora: 'Tropical Rainforests, Orchids',
      fauna: 'Monkeys, Toucans, Jaguars',
    ),
  ];

  ClimateZone? _selectedZone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Climate Zone Explorer', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Visualization Area (Visual Bands)
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Earth Circle representation
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                spreadRadius: 5),
                          ],
                        ),
                        child: ClipOval(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _zones.reversed.map((zone) {
                              // Reversing to put Polar at top if we map purely by list order,
                              // but actual physics is mirrored.
                              // Let's do a symmetric list for a 'globe' slice look
                              return Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedZone = zone),
                                  child: Container(
                                    color: zone.color.withValues(alpha: 0.8),
                                    child: Center(
                                      child: Text(
                                        zone.name.split(' ').first,
                                        style: GoogleFonts.outfit(
                                          color: Colors.black87,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // Atmosphere glow
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Detail Area
            Expanded(
              flex: 4,
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: _selectedZone == null
                    ? Center(
                        child: Text(
                          'Tap a climate zone to learn more.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _selectedZone!.color,
                                  radius: 8,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedZone!.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedZone!.description,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                            const SizedBox(height: 24),
                            _buildInfoRow(LucideIcons.thermometer, 'Temp Range',
                                _selectedZone!.temperatureRange),
                            const SizedBox(height: 12),
                            _buildInfoRow(LucideIcons.cloudRain,
                                'Precipitation', _selectedZone!.precipitation),
                            const SizedBox(height: 12),
                            _buildInfoRow(LucideIcons.flower, 'Flora',
                                _selectedZone!.flora),
                            const SizedBox(height: 12),
                            _buildInfoRow(LucideIcons.footprints, 'Fauna',
                                _selectedZone!.fauna),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.amber),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
