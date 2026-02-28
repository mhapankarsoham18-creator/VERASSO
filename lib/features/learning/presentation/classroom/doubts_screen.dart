import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../data/doubt_model.dart';
import 'ask_doubt_screen.dart'; // Will create next
import 'doubt_controller.dart';

/// A screen that displays a searchable and filterable list of student doubts.
class DoubtsScreen extends ConsumerStatefulWidget {
  /// Creates a [DoubtsScreen] instance.
  const DoubtsScreen({super.key});

  @override
  ConsumerState<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtCard extends StatelessWidget {
  final Doubt doubt;
  const _DoubtCard({required this.doubt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label:
                      Text(doubt.subject, style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.white10,
                ),
                const Spacer(),
                if (doubt.isSolved)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              doubt.questionTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (doubt.questionDescription != null) ...[
              const SizedBox(height: 4),
              Text(doubt.questionDescription!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Asked by ${doubt.authorName ?? 'Student'}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                ),
                const Spacer(),
                const Icon(LucideIcons.messageSquare,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text('${doubt.answerCount}',
                    style: TextStyle(
                        color: Colors.white70)), // Answer count from DB
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _DoubtsScreenState extends ConsumerState<DoubtsScreen> {
  String _selectedSubject = 'All';
  final List<String> _subjects = [
    'All',
    'Physics',
    'Chemistry',
    'Biology',
    'Math',
    'General'
  ];

  @override
  Widget build(BuildContext context) {
    final doubtsAsync = ref.watch(doubtsProvider(_selectedSubject));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Q&A / Doubts'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Subject Filter
            SizedBox(
              height: 120, // push down below appbar
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 50,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final isSelected = subject == _selectedSubject;
                      return ChoiceChip(
                        label: Text(subject),
                        selected: isSelected,
                        onSelected: (val) =>
                            setState(() => _selectedSubject = subject),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Doubts List
            Expanded(
              child: doubtsAsync.when(
                data: (doubts) {
                  if (doubts.isEmpty) {
                    return const Center(child: Text('No doubts asked yet.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: doubts.length,
                    itemBuilder: (context, index) =>
                        _DoubtCard(doubt: doubts[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AskDoubtScreen()));
        },
        label: const Text('Ask Question'),
        icon: const Icon(LucideIcons.helpCircle),
      ),
    );
  }
}
