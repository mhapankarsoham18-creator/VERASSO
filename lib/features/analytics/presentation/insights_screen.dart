import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/ui/glass_container.dart';
import '../../../core/ui/liquid_background.dart';
import '../data/analytics_service.dart';
import '../models/analytics_models.dart';

/// A screen that displays user engagement insights and analytics.
class InsightsScreen extends ConsumerStatefulWidget {
  /// Creates an [InsightsScreen].
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    final userStatsAsync = ref.watch(currentUserStatsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Insights'),
      ),
      body: LiquidBackground(
        child: userStatsAsync.when(
          data: (stats) {
            if (stats == null) {
              return const Center(
                child: Text('Unable to load stats',
                    style: TextStyle(color: Colors.white70)),
              );
            }
            return _buildContent(stats);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(UserStats stats) {
    return ListView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
      children: [
        // Overview Stats
        _buildStatsOverview(stats),
        const SizedBox(height: 20),

        // Time Range Selector
        _buildTimeRangeSelector(),
        const SizedBox(height: 16),

        // Engagement Chart
        _buildEngagementChart(),
        const SizedBox(height: 20),

        // Engagement Breakdown
        _buildEngagementBreakdown(stats),
      ],
    );
  }

  Widget _buildEngagementBreakdown(UserStats stats) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEngagementRow(
              'Likes Received', stats.likesReceived, Colors.redAccent),
          const SizedBox(height: 8),
          _buildEngagementRow(
              'Comments Received', stats.commentsReceived, Colors.blueAccent),
          const SizedBox(height: 8),
          _buildEngagementRow('Engagement Score', stats.engagementScore.toInt(),
              Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildEngagementChart() {
    final service = ref.watch(analyticsServiceProvider);
    final userId = ref.watch(currentUserStatsProvider).value?.userId;

    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<List<EngagementData>>(
      future: service.getUserEngagement(userId, days: _selectedDays),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const GlassContainer(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No engagement data yet',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        final data = snapshot.data!;
        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Engagement Over Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(),
                                e.value.totalEngagement.toDouble()))
                            .toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        ),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEngagementRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(UserStats stats) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Posts', stats.postsCount,
                LucideIcons.fileText, Colors.blueAccent)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Followers', stats.followersCount,
                LucideIcons.users, Colors.greenAccent)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Following', stats.followingCount,
                LucideIcons.userPlus, Colors.purpleAccent)),
      ],
    );
  }

  Widget _buildTimeButton(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return GlassContainer(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTimeButton('7 Days', 7)),
          Expanded(child: _buildTimeButton('30 Days', 30)),
          Expanded(child: _buildTimeButton('90 Days', 90)),
        ],
      ),
    );
  }
}
