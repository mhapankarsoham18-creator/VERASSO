import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/analytics_repository.dart';
import '../data/job_repository.dart';
import '../data/talent_repository.dart';

/// Provider that aggregates analytics data for the current user's talents and jobs.
final userAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final talentRepo = ref.read(talentRepositoryProvider);
  final jobRepo = ref.read(jobRepositoryProvider);
  final analyticsRepo = ref.read(analyticsRepositoryProvider);

  final talents = await talentRepo.getTalents();
  final myId = Supabase.instance.client.auth.currentUser?.id;
  final myTalents = talents.where((t) => t.userId == myId).toList();

  final jobs = await jobRepo.getMyJobRequests(myId ?? '');

  int totalViews = 0;
  int totalImpressions = 0;
  List<Map<String, dynamic>> itemStats = [];

  for (var t in myTalents) {
    final stats = await analyticsRepo.getStats(t.id);
    totalViews += stats['views'] ?? 0;
    totalImpressions += stats['impressions'] ?? 0;
    itemStats.add({
      'title': t.title,
      'type': 'Talent',
      'views': stats['views'],
      'impressions': stats['impressions'],
    });
  }

  for (var j in jobs) {
    final stats = await analyticsRepo.getStats(j.id);
    totalViews += stats['views'] ?? 0;
    totalImpressions += stats['impressions'] ?? 0;
    itemStats.add({
      'title': j.title,
      'type': 'Job',
      'views': stats['views'],
      'impressions': stats['impressions'],
    });
  }

  return {
    'totalViews': totalViews,
    'totalImpressions': totalImpressions,
    'itemStats': itemStats,
  };
});

/// Screen displaying analytics dashboard for the user.
class AnalyticsDashboardScreen extends ConsumerWidget {
  /// Creates an [AnalyticsDashboardScreen].
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(userAnalyticsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        backgroundColor: Colors.transparent,
        actions: [
          analyticsAsync.when(
            data: (data) => IconButton(
              icon: const Icon(LucideIcons.share2),
              tooltip: 'Export Report',
              onPressed: () => _exportReport(data),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: LiquidBackground(
        child: analyticsAsync.when(
          data: (data) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildSummaryCard(
                            'Views',
                            data['totalViews'].toString(),
                            LucideIcons.eye,
                            Colors.blueAccent)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildSummaryCard(
                            'Impressions',
                            data['totalImpressions'].toString(),
                            LucideIcons.barChart3,
                            Colors.purpleAccent)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Your Listings',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...data['itemStats']
                    .map<Widget>((item) => _buildItemTile(item))
                    .toList(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(item['type'] as String,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
          _buildStat(item['views'].toString(), 'Views'),
          const SizedBox(width: 16),
          _buildStat(item['impressions'].toString(), 'Imps'),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }

  void _exportReport(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('Verasso Analytics Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Total Views: ${data['totalViews']}');
    buffer.writeln('Total Impressions: ${data['totalImpressions']}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Item Breakdown:');
    // We need to cast the list to ensure type safety
    final items = data['itemStats'] as List<Map<String, dynamic>>;
    for (var item in items) {
      buffer.writeln('- ${item['title']} (${item['type']})');
      buffer.writeln(
          '  Views: ${item['views']}, Impressions: ${item['impressions']}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Generated by Verasso App');

    // ignore: deprecated_member_use
    Share.share(buffer.toString(), subject: 'Verasso Analytics Report');
  }
}
