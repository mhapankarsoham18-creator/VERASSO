import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import 'services/relay_game_service.dart';

/// A screen for participating in the Knowledge Relay gamified mesh experience.
class RelayGameScreen extends ConsumerStatefulWidget {
  /// Creates a [RelayGameScreen] instance.
  const RelayGameScreen({super.key});

  @override
  ConsumerState<RelayGameScreen> createState() => _RelayGameScreenState();
}

class _RelayGameScreenState extends ConsumerState<RelayGameScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _factController = TextEditingController();
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    final activeRelays = ref.watch(relayGameServiceProvider);
    final gameService = ref.read(relayGameServiceProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Knowledge Relay"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Active Relays'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRelayTab(activeRelays, gameService),
              _buildLeaderboardTab(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _factController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildLeaderboardTab() {
    final relayState = ref.watch(relayGameServiceProvider);

    // Process top relayed users from all active chains
    final stats = <String, int>{};
    for (final relay in relayState.values) {
      for (final userId in relay.idChain) {
        stats[userId] = (stats[userId] ?? 0) + 1;
      }
    }

    final sortedUsers = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedUsers.isEmpty) {
      return const Center(
          child: Text("No relays recorded yet",
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) {
        final entry = sortedUsers[index];
        final myId = ref.read(bluetoothMeshServiceProvider).myId;
        final isMe = entry.key == myId;
        final rank = index + 1;

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? Colors.amber : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.black : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? "You" : "Explorer ${entry.key.substring(0, 4)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isMe ? Colors.blueAccent : Colors.white,
                      ),
                    ),
                    Text(
                      '${entry.value} Relays Completed',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value * 10}', // Simulated Score
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.amberAccent,
                    ),
                  ),
                  const Text('XP',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelayTab(
      Map<String, dynamic> activeRelays, dynamic gameService) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stats / My Score
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                    "Active Relays",
                    activeRelays.length.toString(),
                    LucideIcons.zap,
                    Colors.yellowAccent),
                _buildStatColumn("Best Chain", _calcMaxChain(activeRelays),
                    LucideIcons.trophy, Colors.amberAccent),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Start a New Relay
          const Text("Broadcast New Knowledge",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GlassContainer(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _factController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter a quick fact (e.g. Light speed is...)",
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.blueAccent),
                  onPressed: () {
                    if (_factController.text.isNotEmpty) {
                      gameService.startNewRelay(_factController.text);
                      _factController.clear();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Active Relays List
          const Text("Ongoing Relays",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 12),
          Expanded(
            child: activeRelays.isEmpty
                ? const Center(
                    child: Text("Waiting for peer relays...",
                        style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: activeRelays.length,
                    itemBuilder: (context, index) {
                      final relay = activeRelays.values.elementAt(index);
                      final myId = ref.read(bluetoothMeshServiceProvider).myId;
                      final canPass =
                          myId != null && !relay.idChain.contains(myId);

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    relay.fact,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${relay.length} Hops",
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Chain Visualization
                            SizedBox(
                              height: 30,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: relay.userChain.length,
                                itemBuilder: (context, i) {
                                  return Row(
                                    children: [
                                      Text(
                                        relay.userChain[i],
                                        style: TextStyle(
                                          color: myId != null &&
                                                  relay.userChain[i]
                                                      .contains(myId)
                                              ? Colors.blueAccent
                                              : Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (i < relay.userChain.length - 1)
                                        const Icon(LucideIcons.chevronRight,
                                            size: 12, color: Colors.white24),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (canPass)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  minimumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () =>
                                    gameService.passRelay(relay.id),
                                child: const Text("Pass the Knowledge!",
                                    style: TextStyle(color: Colors.white)),
                              ),
                          ],
                        ),
                      ).animate().slideX(begin: 1, end: 0, duration: 300.ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  String _calcMaxChain(dynamic relays) {
    if (relays.isEmpty) return "0";
    int max = 0;
    // Handle Map or List depending on provider type, casting to dynamic for flexibility
    // Provider definition: Map<String, RelayChain>
    final map = relays as Map<String, dynamic>;
    for (var r in map.values) {
      // r is RelayChain
      if (r.length > max) max = r.length;
    }
    return max.toString();
  }
}
