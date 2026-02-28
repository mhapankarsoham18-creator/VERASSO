import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A simulation screen that allows users to explore the structure and organelles of an animal cell.
class CellStructureSimulation extends StatefulWidget {
  /// Creates a [CellStructureSimulation] instance.
  const CellStructureSimulation({super.key});

  @override
  State<CellStructureSimulation> createState() =>
      _CellStructureSimulationState();
}

/// A widget representing an organelle within the cell simulation.
class OrganelleWidget extends StatelessWidget {
  /// The name of the organelle.
  final String name;

  /// The color used to represent the organelle.
  final Color color;

  /// The radius of the organelle's visual representation.
  final double radius;

  /// Whether this organelle is currently selected by the user.
  final bool isSelected;

  /// Callback when the organelle is tapped.
  final VoidCallback onTap;

  /// Creates an [OrganelleWidget] instance.
  const OrganelleWidget({
    super.key,
    required this.name,
    required this.color,
    required this.radius,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                  const BoxShadow(
                    color: Colors.white24,
                    blurRadius: 10,
                  ),
                ]
              : [const BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        alignment: Alignment.center,
        child: radius > 15
            ? Text(
                name[0],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.6,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );

    if (isSelected) {
      content = content
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 800.ms,
            curve: Curves.easeInOut,
          )
          .shimmer(duration: 2.seconds, color: Colors.white24);
    }

    return content;
  }
}

class _CellStructureSimulationState extends State<CellStructureSimulation> {
  String _selectedOrganelle = "Tap an organelle";
  String _description = "Explore the cell by interacting with its parts.";
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  final Map<String, String> _info = {
    'Nucleus':
        'The control center containing DNA and controlling cell activities.',
    'Mitochondria':
        'Powerhouse of the cell, generates ATP through cellular respiration.',
    'Ribosome':
        'Site of protein synthesis, translates genetic code into proteins.',
    'Cell Membrane':
        'Protective barrier regulating entry and exit of substances.',
    'Cytoplasm':
        'Gel-like substance holding organelles and supporting cellular processes.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Animal Cell Structure'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _resetZoom,
            icon: const Icon(LucideIcons.focus),
            tooltip: 'Reset View',
          ),
        ],
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Interactive Cell Viewer
                  InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 3.0,
                    boundaryMargin: const EdgeInsets.all(100),
                    child: Center(
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: Stack(
                          children: [
                            // Cell Membrane (Outer)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => _select('Cell Membrane'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: _selectedOrganelle == 'Cell Membrane'
                                        ? Colors.greenAccent
                                            .withValues(alpha: 0.3)
                                        : Colors.greenAccent
                                            .withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          _selectedOrganelle == 'Cell Membrane'
                                              ? Colors.greenAccent
                                              : Colors.greenAccent
                                                  .withValues(alpha: 0.7),
                                      width:
                                          _selectedOrganelle == 'Cell Membrane'
                                              ? 5
                                              : 4,
                                    ),
                                    boxShadow:
                                        _selectedOrganelle == 'Cell Membrane'
                                            ? [
                                                BoxShadow(
                                                    color: Colors.greenAccent
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 15,
                                                    spreadRadius: 2)
                                              ]
                                            : [],
                                  ),
                                ),
                              ),
                            ),
                            // Cytoplasm (Fill)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => _select('Cytoplasm'),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            // Nucleus (Center)
                            Align(
                              alignment: Alignment.center,
                              child: OrganelleWidget(
                                name: 'Nucleus',
                                color: Colors.purpleAccent,
                                radius: 40,
                                isSelected: _selectedOrganelle == 'Nucleus',
                                onTap: () => _select('Nucleus'),
                              ),
                            ),
                            // Mitochondria (Random spots)
                            Positioned(
                              top: 80,
                              left: 80,
                              child: OrganelleWidget(
                                name: 'Mitochondria',
                                color: Colors.orange,
                                radius: 15,
                                isSelected:
                                    _selectedOrganelle == 'Mitochondria',
                                onTap: () => _select('Mitochondria'),
                              ),
                            ),
                            Positioned(
                              bottom: 80,
                              right: 80,
                              child: OrganelleWidget(
                                name: 'Mitochondria',
                                color: Colors.orange,
                                radius: 15,
                                isSelected:
                                    _selectedOrganelle == 'Mitochondria',
                                onTap: () => _select('Mitochondria'),
                              ),
                            ),
                            Positioned(
                              top: 120,
                              right: 100,
                              child: OrganelleWidget(
                                name: 'Mitochondria',
                                color: Colors.orange,
                                radius: 15,
                                isSelected:
                                    _selectedOrganelle == 'Mitochondria',
                                onTap: () => _select('Mitochondria'),
                              ),
                            ),

                            // Ribosomes (dots)
                            Positioned(
                              top: 150,
                              right: 60,
                              child: OrganelleWidget(
                                name: 'Ribosome',
                                color: Colors.white,
                                radius: 8,
                                isSelected: _selectedOrganelle == 'Ribosome',
                                onTap: () => _select('Ribosome'),
                              ),
                            ),
                            Positioned(
                              bottom: 120,
                              left: 60,
                              child: OrganelleWidget(
                                name: 'Ribosome',
                                color: Colors.white,
                                radius: 8,
                                isSelected: _selectedOrganelle == 'Ribosome',
                                onTap: () => _select('Ribosome'),
                              ),
                            ),
                            Positioned(
                              top: 100,
                              left: 120,
                              child: OrganelleWidget(
                                name: 'Ribosome',
                                color: Colors.white,
                                radius: 8,
                                isSelected: _selectedOrganelle == 'Ribosome',
                                onTap: () => _select('Ribosome'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Zoom Controls
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _zoomIn,
                            icon: const Icon(LucideIcons.plus,
                                color: Colors.white),
                            tooltip: 'Zoom In',
                          ),
                          Text(
                            '${(_currentScale * 100).toInt()}%',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: _zoomOut,
                            icon: const Icon(LucideIcons.minus,
                                color: Colors.white),
                            tooltip: 'Zoom Out',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: GlassContainer(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.amber,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedOrganelle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _description,
                      style: const TextStyle(fontSize: 16, height: 1.4),
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
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    setState(() {
      _currentScale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _select(String name) {
    setState(() {
      _selectedOrganelle = name;
      _description = _info[name] ?? "Unknown part";
    });
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.5, 3.0);
    _transformationController.value = Matrix4.identity()
      ..multiply(Matrix4.diagonal3(Vector3(newScale, newScale, 1.0)));
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.5, 3.0);
    _transformationController.value = Matrix4.identity()
      ..multiply(Matrix4.diagonal3(Vector3(newScale, newScale, 1.0)));
  }
}
