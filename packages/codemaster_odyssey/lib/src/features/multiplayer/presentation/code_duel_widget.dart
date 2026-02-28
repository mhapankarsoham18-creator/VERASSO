import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/duel_repository.dart';

/// A widget that displays the status and progress of code duels.
class CodeDuelWidget extends ConsumerWidget {
  /// Creates a [CodeDuelWidget] instance.
  const CodeDuelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duel = ref.watch(duelProvider);

    if (duel.status == DuelStatus.finished) {
      return ElevatedButton.icon(
        onPressed: () => ref.read(duelProvider.notifier).startSearch(),
        icon: const Icon(Icons.flash_on),
        label: const Text('SEARCH FOR DUEL'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.black,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (duel.status == DuelStatus.searching)
            Column(
              children: [
                const CircularProgressIndicator(color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Searching for opponent...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          if (duel.status == DuelStatus.starting ||
              duel.status == DuelStatus.ongoing)
            Column(
              children: [
                const Text(
                  'DUEL IN PROGRESS',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PlayerDuelInfo(
                      name: 'YOU',
                      score: duel.playerScore,
                      isPlayer: true,
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _PlayerDuelInfo(
                      name: duel.opponentName ?? 'Unknown',
                      score: duel.opponentScore,
                      isPlayer: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Time Left: ${duel.timeLeft}s',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ).animate().fadeIn().scale(),
        ],
      ),
    );
  }
}

class _PlayerDuelInfo extends StatelessWidget {
  final String name;
  final int score;
  final bool isPlayer;

  const _PlayerDuelInfo({
    required this.name,
    required this.score,
    required this.isPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isPlayer ? Colors.blue : Colors.red,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(
          score.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
