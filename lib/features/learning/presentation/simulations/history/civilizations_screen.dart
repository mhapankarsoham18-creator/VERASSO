import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Represents the key information and achievements of a historical civilization.
class Civilization {
  /// The name of the civilization.
  final String name;

  /// The historical period of the civilization.
  final String period;

  /// The primary location of the civilization.
  final String location;

  /// A brief description of the civilization.
  final String description;

  /// A list of notable achievements.
  final List<String> achievements;

  /// An icon representing the civilization.
  final IconData icon;

  /// A color associated with the civilization's theme.
  final Color color;

  /// Creates a [Civilization] instance.
  const Civilization({
    required this.name,
    required this.period,
    required this.location,
    required this.description,
    required this.achievements,
    required this.icon,
    required this.color,
  });
}

/// A screen for exploring and learning about ancient civilizations and their heritage.
class CivilizationsScreen extends StatefulWidget {
  /// Creates a [CivilizationsScreen] instance.
  const CivilizationsScreen({super.key});

  @override
  State<CivilizationsScreen> createState() => _CivilizationsScreenState();
}

class _CivilizationsScreenState extends State<CivilizationsScreen> {
  final List<Civilization> _civs = [
    Civilization(
      name: 'Ancient Egypt',
      period: '3100 BCE - 30 BCE',
      location: 'Nile Valley, Northeast Africa',
      description:
          'Known for its pyramids, pharaohs, and mummification practices.',
      achievements: [
        'Pyramids of Giza',
        'Hieroglyphics',
        'Papyrus',
        '365-day Calendar'
      ],
      icon: LucideIcons.landmark,
      color: Colors.amber,
    ),
    Civilization(
      name: 'Ancient Greece',
      period: '800 BCE - 146 BCE',
      location: 'Greece and Mediterranean',
      description:
          'The birthplace of democracy, Western philosophy, and the Olympic Games.',
      achievements: [
        'Democracy',
        'Philosophy (Socrates, Plato)',
        'Geometry',
        'Olympics'
      ],
      icon: LucideIcons.columns, // Closest to a temple/pillar
      color: Colors.blueAccent,
    ),
    Civilization(
      name: 'Roman Empire',
      period: '27 BCE - 476 CE',
      location: 'Mediterranean Basin, Europe',
      description:
          'A vast empire known for its law, engineering, and military prowess.',
      achievements: ['Roman Law', 'Aqueducts', 'Concrete', 'Road Network'],
      icon: LucideIcons.swords,
      color: Colors.redAccent,
    ),
    Civilization(
      name: 'Ancient China',
      period: '2070 BCE - 1912 CE',
      location: 'East Asia',
      description: 'One of the world\'s oldest continuous civilizations.',
      achievements: ['Paper', 'Gunpowder', 'Compass', 'Great Wall'],
      icon: LucideIcons.scroll,
      color: Colors.red,
    ),
    Civilization(
      name: 'Mesopotamia',
      period: '4000 BCE - 539 BCE',
      location: 'Tigris-Euphrates River System',
      description: 'Cradle of civilization, home to Sumerians and Babylonians.',
      achievements: [
        'Cuneiform Writing',
        'Wheel',
        'Code of Hammurabi',
        'Irrigation'
      ],
      icon: LucideIcons.bookOpen,
      color: Colors.orange,
    ),
    Civilization(
      name: 'Indus Valley',
      period: '3300 BCE - 1300 BCE',
      location: 'South Asia (modern Pakistan/India)',
      description: 'Known for urban planning and drainage systems.',
      achievements: [
        'Urban Planning',
        'Standardized Weights',
        'Metallurgy',
        'Seal Carving'
      ],
      icon: LucideIcons.layoutGrid,
      color: Colors.teal,
    ),
    Civilization(
      name: 'Maya Civilization',
      period: '2000 BCE - 1697 CE',
      location: 'Mesoamerica (Mexico/Central America)',
      description: 'Noted for its hieroglyphic script, art, and mathematics.',
      achievements: [
        'Complex Calendar',
        'Concept of Zero',
        'Astronomy',
        'Step Pyramids'
      ],
      icon: LucideIcons.star,
      color: Colors.green,
    ),
    Civilization(
      name: 'Inca Empire',
      period: '1438 CE - 1533 CE',
      location: 'Andean South America',
      description: 'Largest empire in pre-Columbian America.',
      achievements: [
        'Machu Picchu',
        'Road System (Qhapaq Ñan)',
        'Terrace Farming',
        'Quipu'
      ],
      icon: LucideIcons.mountain,
      color: Colors.brown,
    ),
  ];

  Civilization? _selectedCiv;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Ancient Civilizations', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        leading: _selectedCiv != null
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => setState(() => _selectedCiv = null))
            : null,
      ),
      body: LiquidBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              _selectedCiv == null ? _buildGrid() : _buildDetail(_selectedCiv!),
        ),
      ),
    );
  }

  Widget _buildDetail(Civilization civ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: civ.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: civ.color.withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(civ.icon, size: 64, color: civ.color),
          ),
          const SizedBox(height: 24),
          Text(
            civ.name,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${civ.period} • ${civ.location}',
            style: const TextStyle(color: Colors.amber, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GlassContainer(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  civ.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Key Achievements',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: civ.achievements.map((achievement) {
                    return Chip(
                      label: Text(achievement),
                      backgroundColor: civ.color.withValues(alpha: 0.1),
                      side: BorderSide(color: civ.color.withValues(alpha: 0.3)),
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _civs.length,
        itemBuilder: (context, index) {
          final civ = _civs[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCiv = civ),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: civ.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(civ.icon, size: 32, color: civ.color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    civ.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    civ.period,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
