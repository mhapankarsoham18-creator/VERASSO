import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/culture_repository.dart';

/// Main screen for the Global Community Hub, showing unlocked realms and stats.
class GlobalCommunityScreen extends ConsumerWidget {
  /// Creates a [GlobalCommunityScreen] instance.
  const GlobalCommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(cultureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'GLOBAL COMMUNITY HUB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'UNLOCKED CULTURAL REALMS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...themes.map((theme) => _ThemeCard(theme: theme)),
          const SizedBox(height: 32),
          const _GlobalStatsWidget(),
        ],
      ),
    );
  }
}

class _GlobalStatsWidget extends StatelessWidget {
  const _GlobalStatsWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Text(
            'GLOBAL APPRENTICES ONLINE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '14,821',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LangChip(lang: 'EN'),
              _LangChip(lang: 'ES'),
              _LangChip(lang: 'FR'),
              _LangChip(lang: 'JP'),
              _LangChip(lang: 'CN'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String lang;
  const _LangChip({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        lang,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final dynamic theme;

  const _ThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.primaryColor.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(theme.icon, color: theme.primaryColor),
        title: Text(
          theme.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          theme.description,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }
}
