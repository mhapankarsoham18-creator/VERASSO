import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:verasso/core/utils/logger.dart';

/// ArGuideCamera renders a camera feed with 2D neon ghost overlays
/// to guide the student through physical tasks (e.g., lab experiments).
class ArGuideCamera extends StatefulWidget {
  final String taskTitle;
  final List<ArGhostOverlay> overlays;
  final VoidCallback? onTaskComplete;

  const ArGuideCamera({
    super.key,
    required this.taskTitle,
    required this.overlays,
    this.onTaskComplete,
  });

  @override
  State<ArGuideCamera> createState() => _ArGuideCameraState();
}

class _ArGuideCameraState extends State<ArGuideCamera> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      appLogger.d('ArGuideCamera: Camera init failed: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed
          if (_isCameraReady && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Positioned.fill(
              child: Center(
                child: Text(
                  'Initializing Camera...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),

          // Ghost Overlays
          ...widget.overlays.map((overlay) => _buildGhostOverlay(overlay)),

          // Task Title Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.taskTitle,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.cyanAccent, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Complete Task Button
          if (widget.onTaskComplete != null)
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: ElevatedButton(
                onPressed: widget.onTaskComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'MARK TASK COMPLETE âœ“',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGhostOverlay(ArGhostOverlay overlay) {
    return Positioned(
      left: overlay.left,
      top: overlay.top,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: Container(
              width: overlay.width,
              height: overlay.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: overlay.color,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: overlay.color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  overlay.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: overlay.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: overlay.color, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Represents a single neon ghost overlay positioned on the camera feed.
class ArGhostOverlay {
  final double left;
  final double top;
  final double width;
  final double height;
  final String label;
  final Color color;

  const ArGhostOverlay({
    required this.left,
    required this.top,
    this.width = 120,
    this.height = 80,
    required this.label,
    this.color = Colors.cyanAccent,
  });
}

