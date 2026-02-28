import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Enum for recognized hand gestures
/// Defines the various hand gestures recognized by the AR system.
enum HandGesture {
  /// Pinch gesture, typically used to grab or move components.
  pinch,

  /// Open palm gesture, typically used to release components.
  openPalm,

  /// Fist gesture, typically used to delete components.
  fist,

  /// Point gesture, typically used to select items from a menu.
  point,

  /// Peace sign gesture, typically used to rotate the view.
  peaceSign,

  /// No specific gesture recognized.
  none,
}

/// Service for detecting hand gestures using Google ML Kit Pose Detection
/// Service for detecting and tracking hand gestures using computer vision.
class HandGestureService {
  final PoseDetector _poseDetector;
  StreamController<HandPosition>? _gestureStream;
  bool _isProcessing = false;

  /// Detection sensitivity threshold (between 0.0 and 1.0).
  /// Higher values require more precise hand placement.
  double sensitivity = 0.7;

  /// Creates a [HandGestureService] instance.
  HandGestureService()
      : _poseDetector = PoseDetector(
          options: PoseDetectorOptions(
            mode: PoseDetectionMode.stream,
            model: PoseDetectionModel.accurate,
          ),
        );

  /// Initialize gesture detection stream
  /// Returns a stream of detected hand positions and gestures.
  Stream<HandPosition> get gestureStream {
    _gestureStream ??= StreamController<HandPosition>.broadcast();
    return _gestureStream!.stream;
  }

  /// Dispose resources
  /// Disposes of the ML detector and closed the gesture stream.
  void dispose() {
    _poseDetector.close();
    _gestureStream?.close();
  }

  /// Process camera image and detect hand gestures
  /// Processes a camera image frame to detect gestures.
  Future<void> processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Detect poses
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final handPosition = _analyzeHandGesture(pose);

        if (handPosition != null && _gestureStream != null) {
          _gestureStream!.add(handPosition);
        }
      } else {
        // No hand detected
        if (_gestureStream != null) {
          _gestureStream!.add(const HandPosition(x: 0, y: 0));
        }
      }
    } catch (e) {
      AppLogger.info('Error processing gesture: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Update sensitivity
  /// Updates the detection sensitivity threshold.
  void setSensitivity(double value) {
    sensitivity = value.clamp(0.0, 1.0);
  }

  /// Analyze pose landmarks to detect hand gestures
  HandPosition? _analyzeHandGesture(Pose pose) {
    final landmarks = pose.landmarks;

    // Get key hand landmarks
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final rightThumb = landmarks[PoseLandmarkType.rightThumb];
    final rightIndex = landmarks[PoseLandmarkType.rightIndex];
    final rightPinky = landmarks[PoseLandmarkType.rightPinky];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];

    if (rightWrist == null || rightIndex == null) {
      return null;
    }

    // Normalize coordinates (-1 to 1)
    final x = (rightWrist.x / 1000.0) - 0.5; // Assuming 1000px width
    final y = (rightWrist.y / 1000.0) - 0.5; // Assuming 1000px height

    // Detect gesture based on landmark positions
    final gesture = _detectGesture(
      rightWrist,
      rightThumb,
      rightIndex,
      rightPinky,
      rightElbow,
    );

    // Calculate confidence based on landmark visibility
    final confidence = (rightWrist.likelihood + (rightIndex.likelihood)) / 2.0;

    return HandPosition(
      x: x.clamp(-1.0, 1.0),
      y: y.clamp(-1.0, 1.0),
      z: 0.0, // Depth not easily available without stereo cameras
      gesture: gesture,
      confidence: confidence,
    );
  }

  /// Convert CameraImage to InputImage
  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation =
          InputImageRotation.rotation90deg; // Assuming portrait
      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      AppLogger.info('Error converting image: $e');
      return null;
    }
  }

  /// Detect specific gesture from landmark positions
  HandGesture _detectGesture(
    PoseLandmark? wrist,
    PoseLandmark? thumb,
    PoseLandmark? index,
    PoseLandmark? pinky,
    PoseLandmark? elbow,
  ) {
    if (wrist == null || index == null) {
      return HandGesture.none;
    }

    // Calculate distances between landmarks
    final thumbIndexDist =
        thumb != null ? _distance(thumb, index) : double.infinity;
    final wristIndexDist = _distance(wrist, index);
    final wristPinkyDist =
        pinky != null ? _distance(wrist, pinky) : double.infinity;

    // Pinch gesture: thumb and index finger close together
    if (thumb != null && thumbIndexDist < 30 * sensitivity) {
      return HandGesture.pinch;
    }

    // Fist: all fingers close to wrist
    if (wristIndexDist < 50 * sensitivity &&
        wristPinkyDist < 50 * sensitivity) {
      return HandGesture.fist;
    }

    // Open palm: fingers spread out
    if (wristIndexDist > 100 * (2.0 - sensitivity)) {
      return HandGesture.openPalm;
    }

    // Point: index extended, others closed
    if (wristIndexDist > 80 * (2.0 - sensitivity) &&
        wristPinkyDist < 60 * sensitivity) {
      return HandGesture.point;
    }

    // Default
    return HandGesture.none;
  }

  /// Calculate Euclidean distance between two landmarks
  double _distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return (dx * dx + dy * dy).abs();
  }
}

/// Provider for gesture service (will be used with Riverpod)
/// Represents the state of the hand gesture service.
class HandGestureServiceState {
  /// The most recently detected hand position.
  final HandPosition? currentPosition;

  /// Whether the gesture detection is currently active.
  final bool isActive;

  /// Any error message encountered during detection.
  final String? error;

  /// Creates a [HandGestureServiceState] instance.
  const HandGestureServiceState({
    this.currentPosition,
    this.isActive = false,
    this.error,
  });

  /// Creates a copy of this state with updated fields.
  HandGestureServiceState copyWith({
    HandPosition? currentPosition,
    bool? isActive,
    String? error,
  }) =>
      HandGestureServiceState(
        currentPosition: currentPosition ?? this.currentPosition,
        isActive: isActive ?? this.isActive,
        error: error,
      );
}

/// Hand position in 3D space (from camera perspective)
/// Represents a hand's position and gesture in 3D camera space.
class HandPosition {
  /// Normalized X coordinate (-1 to 1).
  final double x;

  /// Normalized Y coordinate (-1 to 1).
  final double y;

  /// Estimated depth or Z coordinate.
  final double z;

  /// The recognized hand gesture.
  final HandGesture gesture;

  /// The confidence score of the recognition (0.0 to 1.0).
  final double confidence;

  /// Creates a [HandPosition] instance.
  const HandPosition({
    required this.x,
    required this.y,
    this.z = 0.0,
    this.gesture = HandGesture.none,
    this.confidence = 0.0,
  });

  /// Creates a copy of this [HandPosition] with updated fields.
  HandPosition copyWith({
    double? x,
    double? y,
    double? z,
    HandGesture? gesture,
    double? confidence,
  }) =>
      HandPosition(
        x: x ?? this.x,
        y: y ?? this.y,
        z: z ?? this.z,
        gesture: gesture ?? this.gesture,
        confidence: confidence ?? this.confidence,
      );
}
