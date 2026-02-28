import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../services/quest_service.dart';

/// Provider for list of daily quests.
final dailyQuestsProvider = FutureProvider<List<QuestProgress>>((ref) {
  return ref.watch(questServiceProvider).getDailyQuests();
});

/// Provider for list of weekly quests.
final weeklyQuestsProvider = FutureProvider<List<QuestProgress>>((ref) {
  return ref.watch(questServiceProvider).getWeeklyQuests();
});

/// A screen that displays daily and weekly quests for the user.
class QuestScreen extends ConsumerStatefulWidget {
  /// Creates a [QuestScreen].
  const QuestScreen({super.key});

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Quests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _QuestList(provider: dailyQuestsProvider),
            _QuestList(provider: weeklyQuestsProvider),
          ],
        ),
      ),
    );
  }
}

class _QuestList extends ConsumerWidget {
  final FutureProvider<List<QuestProgress>> provider;

  const _QuestList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(provider);

    return questsAsync.when(
      data: (quests) {
        if (quests.isEmpty) {
          return const Center(
            child: Text(
              'No active quests at the moment.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final progress = quests[index];
            return _QuestCard(progress: progress)
                .animate()
                .fadeIn(delay: (index * 100).ms)
                .slideX(begin: 0.2, end: 0);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final QuestProgress progress;

  const _QuestCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final quest = progress.quest;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(quest.typeIcon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        quest.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress.isCompleted)
                  const Icon(LucideIcons.checkCircle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.currentCount} / ${quest.targetCount}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '+${quest.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progressFraction,
                backgroundColor: Colors.white10,
                color: progress.isCompleted ? Colors.green : Colors.orangeAccent,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
