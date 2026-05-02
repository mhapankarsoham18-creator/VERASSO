import 'package:flutter/material.dart';
import 'dart:async';

class VnDialogueBox extends StatefulWidget {
  final String text;
  final String speakerName;
  final VoidCallback? onComplete;

  const VnDialogueBox({
    super.key,
    required this.text,
    this.speakerName = 'Ira',
    this.onComplete,
  });

  @override
  State<VnDialogueBox> createState() => _VnDialogueBoxState();
}

class _VnDialogueBoxState extends State<VnDialogueBox> {
  String _displayedText = '';
  Timer? _typingTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(VnDialogueBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _typingTimer?.cancel();
    _displayedText = '';
    _currentIndex = 0;

    if (widget.text.isEmpty) return;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    });
  }

  void _completeTypingImmediately() {
    if (_currentIndex < widget.text.length) {
      _typingTimer?.cancel();
      setState(() {
        _displayedText = widget.text;
        _currentIndex = widget.text.length;
      });
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _completeTypingImmediately,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6), // Glassmorphic base
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.speakerName,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _displayedText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
