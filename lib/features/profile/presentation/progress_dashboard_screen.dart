import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

import '../../learning/presentation/widgets/study_timer_widget.dart';
import '../../learning/presentation/widgets/weekly_goals_widget.dart';

/// A comprehensive dashboard displaying user learning progress, charts, and metrics.
class ProgressDashboardScreen extends StatefulWidget {
  /// Creates a [ProgressDashboardScreen].
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _progressService = ProgressTrackingService();

  UserProgressModel? _progress;
  List<DailyProgressModel> _dailyProgress = [];
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Progress')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_progress == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Progress')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.barChart, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No progress data available'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProgress,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadProgress,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(),
              const SizedBox(height: 16),
              _buildLevelProgressCard(),
              const SizedBox(height: 16),
              _buildMetricsGrid(),
              const SizedBox(height: 16),
              _buildPercentilesCard(),
              const SizedBox(height: 16),
              _buildDailyProgressChart(),
              const SizedBox(height: 16),
              StudyTimerWidget(service: _progressService),
              const SizedBox(height: 16),
              WeeklyGoalsWidget(service: _progressService),
              const SizedBox(height: 16),
              _buildSocialMetrics(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Widget _buildDailyProgressChart() {
    if (_dailyProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Points Over Time (Last 30 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailyProgress.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.pointsEarned.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  '${_progress!.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${_progress!.level}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_progress!.levelProgress * 100).toStringAsFixed(0)}% complete',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 24)),
                Text(
                  '${_progress!.achievementsCount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              icon: LucideIcons.graduationCap,
              label: 'Lessons',
              value: '${_progress!.lessonsCompleted}',
              color: Colors.blue,
            ),
            _buildMetricCard(
              icon: LucideIcons.helpCircle,
              label: 'Quizzes',
              value: '${_progress!.quizzesTaken}',
              subtitle:
                  '${(_progress!.quizAverageScore * 100).toStringAsFixed(0)}% avg',
              color: Colors.green,
            ),
            _buildMetricCard(
              icon: LucideIcons.wrench,
              label: 'Projects',
              value:
                  '${_progress!.arProjectsCompleted}/${_progress!.arProjectsCreated}',
              subtitle: 'completed',
              color: Colors.orange,
            ),
            _buildMetricCard(
              icon: LucideIcons.zap,
              label: 'Simulations',
              value: '${_progress!.circuitsSimulated}',
              color: Colors.amber,
            ),
            _buildMetricCard(
              icon: LucideIcons.clock,
              label: 'Study Time',
              value:
                  '${(_progress!.totalStudyTimeMinutes / 60).toStringAsFixed(1)}h',
              color: Colors.purple,
            ),
            _buildMetricCard(
              icon: LucideIcons.flame,
              label: 'Streak',
              value: '${_progress!.streakDays} days',
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${_progress!.level}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_progress!.totalPoints} Points',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.trophy, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Rank #${_progress!.rank}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress to Level ${_progress!.level + 1}'),
                    Text('${_progress!.pointsToNextLevel} pts to go'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress!.levelProgress,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentileBar(String label, double percentile, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              'Top ${(100 - percentile).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentile / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPercentilesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.trendingUp, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'How You Compare',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPercentileBar(
              'Points',
              _progress!.pointsPercentile,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildPercentileBar(
              'Lessons',
              _progress!.lessonsPercentile,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildPercentileBar(
              'Projects',
              _progress!.projectsPercentile,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.users, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Social Engagement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialStat(
                    'Posts', _progress!.postsCreated, Icons.post_add),
                _buildSocialStat(
                    'Comments', _progress!.commentsMade, Icons.comment),
                _buildSocialStat(
                    'Likes', _progress!.likesReceived, Icons.favorite),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialStat(
                    'Followers', _progress!.followersCount, Icons.people),
                _buildSocialStat(
                    'Following', _progress!.followingCount, Icons.person_add),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple.shade300),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final progress = await _progressService.getUserProgressSummary(userId);
      final daily = await _progressService.getDailyProgressHistory(
        userId: userId,
        days: 30,
      );
      setState(() {
        _progress = progress;
        _dailyProgress = daily;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading progress: $e')),
        );
      }
    }
  }
}
