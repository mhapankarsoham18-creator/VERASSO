import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../badge/data/badge_repository.dart';
import '../../badge/domain/badge_model.dart' as badge_model;
import '../data/avatar_repository.dart';
import '../domain/avatar_model.dart';

/// Main screen for viewing the avatar profile, skill tree, and earned badges.
class AvatarScreen extends ConsumerWidget {
  /// Creates an [AvatarScreen] widget.
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarRepositoryProvider).getAvatar();
    final badges = ref.watch(badgeRepositoryProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('AVATAR SYSTEM'),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF6C63FF),
            tabs: [
              Tab(text: 'PROFILE'),
              Tab(text: 'SKILL TREE'),
              Tab(text: 'BADGES'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(avatar: avatar),
            _SkillTreeTab(avatar: avatar),
            _BadgesTab(badges: badges),
          ],
        ),
      ),
    );
  }
}

class _BadgesTab extends StatelessWidget {
  final List<badge_model.Badge> badges;

  const _BadgesTab({required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Center(
        child: Text('No badges yet!', style: TextStyle(color: Colors.white)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge_model.Badge badge = badges[index];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.isUnlocked
                    ? const Color(0xFF2D2D44)
                    : Colors.black26,
                border: badge.isUnlocked
                    ? Border.all(color: const Color(0xFFFFD700))
                    : null,
                boxShadow: badge.isUnlocked
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                badge.iconData,
                color: badge.isUnlocked ? const Color(0xFFFFD700) : Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: badge.isUnlocked ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ).animate(delay: (100 * index).ms).scale();
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Avatar avatar;

  const _ProfileTab({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Avatar Representation (Placeholder)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2D2D44),
              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
            ),
            child: const Icon(Icons.person, size: 80, color: Colors.white),
          ).animate().scale(),

          const SizedBox(height: 16),

          Text(
            avatar.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          Text(
            'Level ${avatar.level} Code Apprentice',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),

          // Stats
          _StatRow(
            label: 'LOGIC',
            level: avatar.getStatLevel(SkillType.logic),
            color: const Color(0xFF6C63FF),
          ),
          _StatRow(
            label: 'SYNTAX',
            level: avatar.getStatLevel(SkillType.syntax),
            color: const Color(0xFF00E5FF),
          ),
          _StatRow(
            label: 'PROJECTS',
            level: avatar.getStatLevel(SkillType.projects),
            color: const Color(0xFFFFCC80),
          ),
        ],
      ),
    );
  }
}

class _SkillTreeTab extends StatelessWidget {
  final Avatar avatar;

  const _SkillTreeTab({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: avatar.skills.length,
      itemBuilder: (context, index) {
        final skill = avatar.skills[index];
        return Card(
          color: skill.isUnlocked ? const Color(0xFF2D2D44) : Colors.black26,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              skill.isUnlocked ? Icons.check_circle : Icons.lock,
              color: skill.isUnlocked ? const Color(0xFF00E5FF) : Colors.grey,
            ),
            title: Text(
              skill.name,
              style: TextStyle(
                color: skill.isUnlocked ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              skill.description,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            trailing: skill.isUnlocked
                ? null
                : Chip(
                    label: Text('${skill.cost} SP'),
                    backgroundColor: Colors.grey.shade800,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
          ),
        ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2);
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int level;
  final Color color;

  const _StatRow({
    required this.label,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: level / 10.0, // Assuming max level 10 for bar
                backgroundColor: const Color(0xFF2D2D44),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text('Lvl $level', style: const TextStyle(color: Colors.white)),
        ],
      ).animate().fadeIn().slideX(begin: -0.1),
    );
  }
}
