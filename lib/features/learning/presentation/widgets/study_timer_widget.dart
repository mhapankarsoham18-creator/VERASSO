import 'dart:async';

import 'package:flutter/material.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

/// A widget that provides a timer for tracking study sessions.
class StudyTimerWidget extends StatefulWidget {
  /// The service used to log study sessions.
  final ProgressTrackingService service;

  /// Creates a [StudyTimerWidget] instance.
  const StudyTimerWidget({super.key, required this.service});

  @override
  State<StudyTimerWidget> createState() => _StudyTimerWidgetState();
}

class _StudyTimerWidgetState extends State<StudyTimerWidget> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _isRunning ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRunning ? Colors.blue : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer,
                color: _isRunning ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRunning ? 'Studying...' : 'Study Timer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatTime(_seconds),
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Monospace',
                      color: _isRunning ? Colors.blue : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _toggleTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isRunning ? 'STOP' : 'START'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  Future<void> _stopTimer() async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    if (_seconds > 60) {
      final minutes = (_seconds / 60).ceil();
      await widget.service.logStudySession(minutes, 'General Study');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged $minutes minutes of study time!')),
        );
      }
    }

    // Reset or keep? Let's reset for now
    setState(() => _seconds = 0);
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }
}
