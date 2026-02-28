import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'timeline_data.dart'; // Import the data

/// Represents an event within the timeline reconstruction game.
class GameEvent {
  /// The underlying timeline event.
  final TimelineEvent event;

  /// The correct chronological index of the event within the current game set.
  final int correctIndex;

  /// Creates a [GameEvent] instance.
  GameEvent({required this.event, required this.correctIndex});
}

/// A screen for an interactive game where users reorder scrambled historical events.
class TimelineReconstructorScreen extends StatefulWidget {
  /// Creates a [TimelineReconstructorScreen] instance.
  const TimelineReconstructorScreen({super.key});

  @override
  State<TimelineReconstructorScreen> createState() =>
      _TimelineReconstructorScreenState();
}

class _TimelineReconstructorScreenState
    extends State<TimelineReconstructorScreen> {
  late List<GameEvent> _scrambledEvents;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Timeline Reconstructor'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw),
            onPressed: _startNewGame,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: LiquidBackground(
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.amber, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chronological collapse detected! Drag the events into their correct historical order.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = _scrambledEvents.removeAt(oldIndex);
                      _scrambledEvents.insert(newIndex, item);
                      _checkOrder();
                    });
                  },
                  children: [
                    for (int i = 0; i < _scrambledEvents.length; i++)
                      _buildEventCard(i, _scrambledEvents[i]),
                  ],
                ),
              ),
              if (_isSuccess)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton.icon(
                    onPressed: _startNewGame,
                    icon: const Icon(LucideIcons.check),
                    label: const Text('MISSION COMPLETE - PLAY AGAIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  Widget _buildEventCard(int index, GameEvent gameEvent) {
    // Unique key based on the event title to verify identity
    return KeyedSubtree(
      key: ValueKey(gameEvent.event.title),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Text('${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gameEvent.event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(gameEvent.event.date,
                      style:
                          const TextStyle(color: Colors.amber, fontSize: 12)),
                  Text(gameEvent.event.description,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
            const Icon(LucideIcons.gripVertical, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _checkOrder() {
    bool correct = true;
    for (int i = 0; i < _scrambledEvents.length; i++) {
      if (_scrambledEvents[i].correctIndex != i) {
        correct = false;
        break;
      }
    }

    if (correct) {
      setState(() => _isSuccess = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timeline Restored! Well done, historian.'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  void _startNewGame() {
    // 1. Select 5 random events
    final allEvents = List<TimelineEvent>.from(allTimelineEvents)..shuffle();
    final selectedEvents = allEvents.take(5).toList();

    // 2. Sort them to find correct order
    final sortedEvents = List<TimelineEvent>.from(selectedEvents)
      ..sort((a, b) => a.year.compareTo(b.year));

    // 3. Create GameEvents with correct indices
    final gameEvents = selectedEvents.map((e) {
      return GameEvent(
        event: e,
        correctIndex: sortedEvents.indexOf(e),
      );
    }).toList();

    // 4. Shuffle for the game
    setState(() {
      _scrambledEvents = gameEvents..shuffle();
      _isSuccess = false;
    });
  }
}
