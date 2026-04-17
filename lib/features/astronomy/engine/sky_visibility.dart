import 'dart:math' as math;

enum SkyViewState {
  calibrating,
  searching,
  skyVisible,
  obstructed,
  pointingDown,
  permissionLimited,
  sensorUnavailable,
}

class SkyCameraMetrics {
  final double brightness;
  final double contrast;
  final double roughness;
  final double? blueRatio;

  SkyCameraMetrics({
    required this.brightness,
    required this.contrast,
    required this.roughness,
    this.blueRatio,
  });
}

class SkyVisibilityReport {
  final SkyViewState state;
  final String title;
  final String detail;
  final double confidence;
  final bool shouldRenderSky;
  final bool canDiscover;
  final bool isEstimated;

  SkyVisibilityReport({
    required this.state,
    required this.title,
    required this.detail,
    required this.confidence,
    required this.shouldRenderSky,
    required this.canDiscover,
    this.isEstimated = false,
  });
}

class SkyVisibilityEstimator {
  final List<double> _pitchSamples = <double>[];
  final List<double> _headingSamples = <double>[];
  SkyCameraMetrics? _cameraMetrics;
  DateTime? _cameraMetricsAt;

  void updatePitch(double pitch) {
    _pushSample(_pitchSamples, pitch);
  }

  void updateHeading(double heading) {
    _pushSample(_headingSamples, heading);
  }

  void updateCameraMetrics(SkyCameraMetrics metrics) {
    _cameraMetrics = metrics;
    _cameraMetricsAt = DateTime.now();
  }

  SkyVisibilityReport buildReport({
    required bool hasMotionData,
    required bool hasCompassData,
    required bool hasCameraPermission,
    required bool hasCameraAnalysis,
    required bool hasLocationLock,
  }) {
    if (!hasMotionData) {
      return SkyVisibilityReport(
        state: SkyViewState.sensorUnavailable,
        title: 'MOTION SENSOR OFFLINE',
        detail: 'Tilt sensing is unavailable. Astro needs motion data to align the sky.',
        confidence: 0,
        shouldRenderSky: false,
        canDiscover: false,
      );
    }

    if (_pitchSamples.length < 4) {
      return SkyVisibilityReport(
        state: SkyViewState.calibrating,
        title: 'CALIBRATING SKY SCAN',
        detail: 'Hold steady for a moment while Astro locks your viewing angle.',
        confidence: 0.1,
        shouldRenderSky: false,
        canDiscover: false,
      );
    }

    final double pitch = _average(_pitchSamples);
    final bool compassReady = hasCompassData && _headingSamples.isNotEmpty;

    if (pitch < 10) {
      return SkyVisibilityReport(
        state: SkyViewState.pointingDown,
        title: 'POINT TOWARD THE SKY',
        detail: 'The phone is aimed below the horizon. Lift it upward to start scanning.',
        confidence: 0,
        shouldRenderSky: false,
        canDiscover: false,
      );
    }

    if (pitch < 24) {
      return SkyVisibilityReport(
        state: SkyViewState.obstructed,
        title: 'SKY TOO LOW IN FRAME',
        detail: 'Raise the phone higher above the horizon to reveal celestial objects.',
        confidence: _pitchConfidence(pitch),
        shouldRenderSky: false,
        canDiscover: false,
      );
    }

    if (!compassReady) {
      return SkyVisibilityReport(
        state: SkyViewState.calibrating,
        title: 'COMPASS CALIBRATING',
        detail: 'Move the phone in a gentle figure-eight so Astro can align the star field.',
        confidence: 0.2,
        shouldRenderSky: false,
        canDiscover: false,
      );
    }

    final SkyCameraMetrics? metrics = _hasFreshCameraMetrics ? _cameraMetrics : null;
    final double pitchConfidence = _pitchConfidence(pitch);
    final String locationNote = hasLocationLock
        ? ''
        : ' Using fallback coordinates until location is available.';

    if (metrics != null) {
      final double cameraConfidence = _cameraConfidence(metrics);
      final double combined = (pitchConfidence * 0.55) + (cameraConfidence * 0.45);

      if (combined >= 0.6) {
        return SkyVisibilityReport(
          state: SkyViewState.skyVisible,
          title: 'OPEN SKY LOCKED',
          detail: 'Sky visibility confirmed with on-device sensors.${locationNote.isEmpty ? '' : locationNote}',
          confidence: combined,
          shouldRenderSky: true,
          canDiscover: true,
        );
      }

      if (cameraConfidence < 0.42) {
        return SkyVisibilityReport(
          state: SkyViewState.obstructed,
          title: 'NO OPEN SKY DETECTED',
          detail: 'Astro is seeing a blocked or indoor view. Step toward open sky and try again.${locationNote.isEmpty ? '' : locationNote}',
          confidence: combined,
          shouldRenderSky: false,
          canDiscover: false,
        );
      }

      return SkyVisibilityReport(
        state: SkyViewState.searching,
        title: 'SEARCHING FOR CLEAR SKY',
        detail: 'Aim higher or sweep toward a clearer patch of sky for a stronger lock.${locationNote.isEmpty ? '' : locationNote}',
        confidence: combined,
        shouldRenderSky: false,
        canDiscover: false,
      );
    }

    if (hasCameraPermission && hasCameraAnalysis) {
      return SkyVisibilityReport(
        state: SkyViewState.searching,
        title: 'CHECKING THE SKY',
        detail: 'Camera sampling is warming up. Keep pointing at open sky for a moment.${locationNote.isEmpty ? '' : locationNote}',
        confidence: pitchConfidence * 0.5,
        shouldRenderSky: false,
        canDiscover: false,
      );
    }

    if (!hasCameraPermission) {
      final bool estimatedVisible = pitchConfidence >= 0.82 && _headingJitter() < 45;
      return SkyVisibilityReport(
        state: estimatedVisible ? SkyViewState.skyVisible : SkyViewState.permissionLimited,
        title: estimatedVisible ? 'ESTIMATED SKY LOCK' : 'CAMERA CHECK DISABLED',
        detail: estimatedVisible
            ? 'Astro is using motion-only estimation. Camera access improves indoor filtering.${locationNote.isEmpty ? '' : locationNote}'
            : 'Allow camera access for stronger indoor vs open-sky detection. Motion-only mode is staying conservative.${locationNote.isEmpty ? '' : locationNote}',
        confidence: estimatedVisible ? math.max(0.45, pitchConfidence * 0.7) : pitchConfidence * 0.35,
        shouldRenderSky: estimatedVisible,
        canDiscover: estimatedVisible,
        isEstimated: estimatedVisible,
      );
    }

    return SkyVisibilityReport(
      state: SkyViewState.searching,
      title: 'SENSOR LOCK IN PROGRESS',
      detail: 'Astro is waiting for a clean sky sample before it reveals the map.${locationNote.isEmpty ? '' : locationNote}',
      confidence: pitchConfidence * 0.4,
      shouldRenderSky: false,
      canDiscover: false,
    );
  }

  bool get _hasFreshCameraMetrics {
    final DateTime? cameraMetricsAt = _cameraMetricsAt;
    if (cameraMetricsAt == null) {
      return false;
    }
    return DateTime.now().difference(cameraMetricsAt) <= Duration(seconds: 4);
  }

  double _cameraConfidence(SkyCameraMetrics metrics) {
    final double smoothness = (1 - (metrics.roughness * 3.2)).clamp(0.0, 1.0);
    final double uniformity = (1 - (metrics.contrast * 2.4)).clamp(0.0, 1.0);
    final double dayScore = metrics.brightness > 0.55
        ? 1
        : metrics.brightness > 0.4
            ? 0.7
            : 0.2;
    final double nightScore = metrics.brightness < 0.18
        ? 0.85
        : metrics.brightness < 0.28
            ? 0.55
            : 0.1;
    final double brightnessScore = math.max(dayScore, nightScore).toDouble();
    final double colorScore;
    final double? blueRatio = metrics.blueRatio;
    if (blueRatio == null) {
      colorScore = 0.5;
    } else if (blueRatio > 0.38) {
      colorScore = 1;
    } else if (blueRatio > 0.34) {
      colorScore = 0.7;
    } else {
      colorScore = 0.25;
    }

    return (smoothness * 0.35) +
        (uniformity * 0.25) +
        (brightnessScore * 0.25) +
        (colorScore * 0.15);
  }

  double _pitchConfidence(double pitch) {
    return ((pitch - 20) / 45).clamp(0.0, 1.0);
  }

  double _headingJitter() {
    if (_headingSamples.length < 2) {
      return 0;
    }

    double maxDelta = 0;
    for (int i = 1; i < _headingSamples.length; i++) {
      final double rawDelta = (_headingSamples[i] - _headingSamples[i - 1]).abs();
      final double wrappedDelta = rawDelta > 180 ? 360 - rawDelta : rawDelta;
      maxDelta = math.max(maxDelta, wrappedDelta);
    }
    return maxDelta;
  }

  double _average(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return values.reduce((double a, double b) => a + b) / values.length;
  }

  void _pushSample(List<double> target, double value) {
    target.add(value);
    if (target.length > 18) {
      target.removeAt(0);
    }
  }
}
