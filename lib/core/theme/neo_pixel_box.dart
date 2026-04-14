import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'colors.dart';

/// Blends Neumorphism (soft background matching) with 
/// Pixelated 3D (hard edges and offset solid shadows) 
/// synchronized with device hardware tilt (Accelerometer).
class NeoPixelBox extends StatefulWidget {
  final Widget child;
  final double padding;
  final VoidCallback? onTap;
  final bool isButton;
  final bool enableTilt;
  final Color backgroundColor;

  const NeoPixelBox({
    super.key,
    required this.child,
    this.padding = 24.0,
    this.onTap,
    this.isButton = false,
    this.enableTilt = true,
    this.backgroundColor = AppColors.neutralBg,
  });

  @override
  State<NeoPixelBox> createState() => _NeoPixelBoxState();
}

class _NeoPixelBoxState extends State<NeoPixelBox> {
  bool _isPressed = false;
  double _tiltX = 4.0;
  double _tiltY = 4.0;
  StreamSubscription? _accelSub;

  @override
  void initState() {
    super.initState();
    if (widget.enableTilt) {
      _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        // Accelerometer uses standard gravity 9.8 m/s^2.
        // We clamp and map it to a max pixel depth of ~8 pixels
        if (mounted) {
          setState(() {
            _tiltX = (event.x * -1.5).clamp(-8.0, 8.0);
            _tiltY = (event.y * 1.5).clamp(-8.0, 8.0);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When pressed, the box flattens completely
    final xOffset = _isPressed ? 0.0 : _tiltX;
    final yOffset = _isPressed ? 0.0 : max(2.0, _tiltY); // Maintain slight bottom gravity minimum

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      } : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: widget.enableTilt ? const Duration(milliseconds: 100) : const Duration(milliseconds: 150),
        curve: Curves.easeOutCirc,
        padding: EdgeInsets.all(widget.padding),
        transform: Matrix4.translationValues(
          _isPressed ? _tiltX : 0.0, 
          _isPressed ? _tiltY : 0.0, 
          0.0
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isButton ? AppColors.primary : AppColors.textPrimary, // Hard pixel borders
            width: 3 
          ),
          // Hard 3D pixel shadow dynamically shifting
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.isButton ? AppColors.primary.withAlpha(204) : AppColors.shadowDark,
                    offset: Offset(xOffset, yOffset),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                  // Secondary high-contrast highlight to enforce the blocky voxel illusion
                  BoxShadow(
                    color: AppColors.shadowLight,
                    offset: Offset(-xOffset.clamp(-3.0, 3.0), -yOffset.clamp(-3.0, 3.0)),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}
