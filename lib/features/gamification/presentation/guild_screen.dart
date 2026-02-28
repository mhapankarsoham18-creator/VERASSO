import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../services/guild_service.dart';

/// Provider for the user's current guild.
final myGuildProvider = FutureProvider<Guild?>((ref) {
  return ref.watch(guildServiceProvider).getMyGuild();
});

/// A screen that displays the user's guild or allows joining/creating one.
class GuildScreen extends ConsumerWidget {
  /// Creates a [GuildScreen].
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGuildAsync = ref.watch(myGuildProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Guilds'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: myGuildAsync.when(
          data: (guild) => guild != null
              ? _GuildDetailView(guild: guild)
              : const _GuildDiscoveryView(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _GuildDetailView extends ConsumerWidget {
  final Guild guild;

  const _GuildDetailView({required this.guild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
      child: Column(
        children: [
          // Guild Header
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: guild.emblemUrl != null
                      ? NetworkImage(guild.emblemUrl!)
                      : null,
                  child: guild.emblemUrl == null
                      ? const Icon(LucideIcons.users, size: 40)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  guild.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (guild.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      guild.description!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Members', value: '${guild.memberCount}/${guild.maxMembers}'),
                    _StatItem(label: 'Total XP', value: '${guild.guildXP}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Guild Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite functionality coming soon')),
                    );
                  },
                  icon: const Icon(LucideIcons.userPlus),
                  label: const Text('Invite'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey.shade900,
                        title: const Text('Leave Guild?'),
                        content: const Text('Are you sure you want to leave this guild?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Leave', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(guildServiceProvider).leaveGuild();
                      ref.invalidate(myGuildProvider);
                    }
                  },
                  icon: const Icon(LucideIcons.logOut),
                  label: const Text('Leave'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuildDiscoveryView extends ConsumerStatefulWidget {
  const _GuildDiscoveryView();

  @override
  ConsumerState<_GuildDiscoveryView> createState() => _GuildDiscoveryViewState();
}

class _GuildDiscoveryViewState extends ConsumerState<_GuildDiscoveryView> {
  final _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
      child: Column(
        children: [
          const Text(
            'Discover Guilds',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join a guild to earn collective XP and compete in seasonal challenges.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          // Create Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guild creation coming soon')),
                );
              },
              icon: const Icon(LucideIcons.plus),
              label: const Text('Create New Guild'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a guild...',
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Simplified Guild List
          const Expanded(
            child: Center(
              child: Text(
                'Explore feature coming soon!',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
