import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/immersive_fallback_view.dart';

import '../../data/ar_project_model.dart';
import '../../data/ar_project_repository.dart';
import '../../data/hand_gesture_service.dart';
import 'ar_component_menu.dart';
import 'ar_simulation_view.dart';

/// Main AR Circuit Builder Screen
class ArCircuitBuilderScreen extends ConsumerStatefulWidget {
  /// Existing project to load for editing (optional).
  final ArProject? existingProject;

  /// Creates an [ArCircuitBuilderScreen] instance.
  const ArCircuitBuilderScreen({super.key, this.existingProject});

  @override
  ConsumerState<ArCircuitBuilderScreen> createState() =>
      _ArCircuitBuilderScreenState();
}

class _ArCircuitBuilderScreenState
    extends ConsumerState<ArCircuitBuilderScreen> {
  CameraController? _cameraController;
  HandGestureService? _gestureService;
  bool _isCameraInitialized = false;
  bool _showComponentMenu = false;
  bool _showSimulation = false;
  String? _error;
  bool _isConnectionMode = false;
  ArComponent? _connectionStart;

  // Current project state
  List<ArComponent> _components = [];
  List<ComponentConnection> _connections = [];
  ArComponent? _selectedComponent;
  HandPosition? _currentHandPosition;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: ImmersiveFallbackView(
          title: 'AR Not Available',
          description: _error!,
          child: _build2DEditor(),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AR Circuit Builder'),
        backgroundColor: Colors.black54,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save),
            onPressed: _saveProject,
            tooltip: 'Save Project',
          ),
          IconButton(
            icon: const Icon(LucideIcons.play),
            onPressed: _runSimulation,
            tooltip: 'Run Simulation',
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: _shareProject,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

          // Hand tracking overlay
          if (_currentHandPosition != null) _buildHandTrackingOverlay(),

          // Component visualization
          ..._buildComponentOverlays(),

          // Gesture indicator
          if (_currentHandPosition != null)
            Positioned(
              top: 100,
              right: 20,
              child: _buildGestureIndicator(_currentHandPosition!.gesture),
            ),

          // Component menu
          if (_showComponentMenu)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ArComponentMenu(
                onComponentSelected: _addComponent,
                onClose: () => setState(() => _showComponentMenu = false),
              ),
            ),

          // Simulation overlay
          if (_showSimulation)
            Positioned.fill(
              child: ArSimulationView(
                components: _components,
                connections: _connections,
                onClose: () => setState(() => _showSimulation = false),
              ),
            ),

          // Bottom toolbar
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _gestureService?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Load existing project if provided
    if (widget.existingProject != null) {
      _components = List.from(widget.existingProject!.components);
      _connections = List.from(widget.existingProject!.connections);
    }
  }

  void _addComponent(String componentLibraryId, String name, String category) {
    final newComponent = ArComponent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      componentLibraryId: componentLibraryId,
      name: name,
      category: category,
      transform: Transform3D(
        x: _currentHandPosition?.x ?? 0.0,
        y: _currentHandPosition?.y ?? 0.0,
        z: 0.0,
      ),
    );

    setState(() {
      _components.add(newComponent);
      _showComponentMenu = false;
    });
  }

  Widget _build2DEditor() {
    return Column(
      children: [
        const SizedBox(height: 100),
        const Text('2D INTERACTION MODE',
            style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        const SizedBox(height: 20),
        Expanded(
          child: Stack(
            children: _buildComponentOverlays(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildToolbarButton(
              LucideIcons.plus,
              'Add',
              () => setState(() => _showComponentMenu = true),
            ),
            _buildToolbarButton(
              LucideIcons.link,
              'Connect',
              () {
                setState(() {
                  _isConnectionMode = !_isConnectionMode;
                  _connectionStart = null;
                });
                if (_isConnectionMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Select two components to connect')),
                  );
                }
              },
            ),
            _buildToolbarButton(
              LucideIcons.info,
              'Help',
              () => _showGestureHelp(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildComponentOverlays() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return _components.map((component) {
      final x = (component.transform.x + 1.0) / 2.0 * screenWidth;
      final y = (component.transform.y + 1.0) / 2.0 * screenHeight;

      return Positioned(
        left: x - 30,
        top: y - 30,
        child: GestureDetector(
          onTap: () {
            if (_isConnectionMode) {
              _handleConnectionModeTap(component);
            } else {
              setState(() => _selectedComponent = component);
            }
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getComponentColor(component.category),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedComponent?.id == component.id
                    ? Colors.yellowAccent
                    : Colors.white54,
                width: _selectedComponent?.id == component.id ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getComponentIcon(component.category),
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  component.name.split(' ').first,
                  style: const TextStyle(fontSize: 8, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildGestureIndicator(HandGesture gesture) {
    String text;
    Color color;
    IconData icon;

    switch (gesture) {
      case HandGesture.pinch:
        text = 'Grab';
        color = Colors.blueAccent;
        icon = LucideIcons.move;
        break;
      case HandGesture.openPalm:
        text = 'Release';
        color = Colors.greenAccent;
        icon = LucideIcons.hand;
        break;
      case HandGesture.fist:
        text = 'Delete';
        color = Colors.redAccent;
        icon = LucideIcons.trash2;
        break;
      case HandGesture.point:
        text = 'Point';
        color = Colors.purpleAccent;
        icon = LucideIcons.mousePointer2;
        break;
      default:
        return const SizedBox.shrink();
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildHandTrackingOverlay() {
    final position = _currentHandPosition!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final x = (position.x + 1.0) / 2.0 * screenWidth;
    final y = (position.y + 1.0) / 2.0 * screenHeight;

    return Positioned(
      left: x - 20,
      top: y - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.greenAccent.withValues(alpha: 0.5),
          border: Border.all(color: Colors.greenAccent, width: 2),
        ),
        child: const Icon(LucideIcons.hand, size: 20, color: Colors.white),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 1000.ms),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Color _getComponentColor(String category) {
    switch (category) {
      case 'power':
        return Colors.redAccent.withValues(alpha: 0.7);
      case 'resistor':
        return Colors.orangeAccent.withValues(alpha: 0.7);
      case 'led':
        return Colors.blueAccent.withValues(alpha: 0.7);
      case 'capacitor':
        return Colors.purpleAccent.withValues(alpha: 0.7);
      case 'switch':
        return Colors.greenAccent.withValues(alpha: 0.7);
      default:
        return Colors.grey.withValues(alpha: 0.7);
    }
  }

  IconData _getComponentIcon(String category) {
    switch (category) {
      case 'power':
        return LucideIcons.battery;
      case 'resistor':
        return LucideIcons.wind;
      case 'led':
        return LucideIcons.lightbulb;
      case 'capacitor':
        return LucideIcons.database;
      case 'switch':
        return LucideIcons.toggleRight;
      default:
        return LucideIcons.box;
    }
  }

  void _handleConnectionModeTap(ArComponent component) {
    if (_connectionStart == null) {
      setState(() {
        _connectionStart = component;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Selected ${component.name}. Select another to connect.')),
      );
    } else if (_connectionStart!.id != component.id) {
      setState(() {
        _connections.add(ComponentConnection(
          fromComponentId: _connectionStart!.id,
          toComponentId: component.id,
        ));
        _isConnectionMode = false;
        _connectionStart = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Components connected!')),
      );
    }
  }

  void _handleDelete() {
    // Delete selected component
    if (_selectedComponent != null) {
      setState(() {
        _components.removeWhere((c) => c.id == _selectedComponent!.id);
        _selectedComponent = null;
      });
    }
  }

  void _handleGesture(HandPosition handPosition) {
    switch (handPosition.gesture) {
      case HandGesture.pinch:
        _handlePinch(handPosition);
        break;
      case HandGesture.openPalm:
        _handleRelease();
        break;
      case HandGesture.fist:
        _handleDelete();
        break;
      case HandGesture.point:
        _handlePoint(handPosition);
        break;
      default:
        break;
    }
  }

  void _handlePinch(HandPosition position) {
    // Grab nearest component or create new one from menu
    if (_showComponentMenu) {
      setState(() {
        _showComponentMenu = false;
      });
    }
  }

  void _handlePoint(HandPosition position) {
    // Point to select component or show menu
    setState(() {
      _showComponentMenu = true;
    });
  }

  void _handleRelease() {
    // Release currently held component
    if (_selectedComponent != null) {
      setState(() {
        _selectedComponent = null;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Camera permission denied';
        });
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found';
        });
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Initialize gesture service
      _gestureService = HandGestureService();
      _gestureService!.gestureStream.listen((handPosition) {
        setState(() {
          _currentHandPosition = handPosition;
          _handleGesture(handPosition);
        });
      });

      // Start streaming camera images to gesture detector
      _cameraController!.startImageStream((image) {
        _gestureService?.processImage(image);
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _runSimulation() async {
    setState(() {
      _showSimulation = true;
    });
  }

  Future<void> _saveProject() async {
    final repo = ref.read(arProjectRepositoryProvider);

    if (widget.existingProject != null) {
      // Update existing
      try {
        final updated = widget.existingProject!.copyWith(
          components: _components,
          connections: _connections,
        );
        await repo.updateProject(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      }
    } else {
      // Create new - ask for title first
      final title = await _showTitleDialog();
      if (title == null || title.isEmpty) return;

      try {
        await repo.createProject(
          title: title,
          components: _components,
          connections: _connections,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project saved!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
    }
  }

  Future<void> _shareProject() async {
    if (widget.existingProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the project first before sharing!')),
      );
      return;
    }

    String friendId = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Project'),
        content: TextField(
          onChanged: (value) => friendId = value,
          decoration: const InputDecoration(labelText: 'Friend User ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, friendId),
            child: const Text('Share'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await ref
            .read(arProjectRepositoryProvider)
            .shareProjectWithFriend(widget.existingProject!.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project shared!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to share: $e')),
          );
        }
      }
    }
  }

  void _showGestureHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hand Gestures'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GestureHelpItem(
                icon: LucideIcons.hand, text: 'Pinch: Grab component'),
            _GestureHelpItem(
                icon: LucideIcons.hand, text: 'Open Palm: Release'),
            _GestureHelpItem(icon: LucideIcons.hand, text: 'Fist: Delete'),
            _GestureHelpItem(
                icon: LucideIcons.hand, text: 'Point: Select menu'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTitleDialog() async {
    String title = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Project'),
        content: TextField(
          onChanged: (value) => title = value,
          decoration: const InputDecoration(labelText: 'Project Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, title),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _GestureHelpItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GestureHelpItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
