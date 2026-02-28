import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

/// A widget that displays the user's weekly learning goals and their progress.
class WeeklyGoalsWidget extends StatefulWidget {
  /// The service used to manage goals.
  final ProgressTrackingService service;

  /// Creates a [WeeklyGoalsWidget] instance.
  const WeeklyGoalsWidget({super.key, required this.service});

  @override
  State<WeeklyGoalsWidget> createState() => _WeeklyGoalsWidgetState();
}

class _WeeklyGoalsWidgetState extends State<WeeklyGoalsWidget> {
  List<WeeklyGoalModel> _goals = [];
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Goals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plusCircle),
                  onPressed: _addGoal,
                  tooltip: 'Set New Goal',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_goals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No goals set for this week.\nTap + to start!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  final progress =
                      (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_getGoalTitle(goal.goalType)),
                            Text('${goal.currentValue} / ${goal.targetValue}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              progress >= 1.0 ? Colors.green : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _addGoal() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set New Weekly Goal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.clock, color: Colors.blue),
              title: const Text('Study Time'),
              subtitle: const Text('Target: 120 minutes'),
              onTap: () => Navigator.pop(context, 'study_time'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.bookOpen, color: Colors.green),
              title: const Text('Lessons Completed'),
              subtitle: const Text('Target: 5 lessons'),
              onTap: () => Navigator.pop(context, 'lessons_completed'),
            ),
            ListTile(
              leading:
                  const Icon(LucideIcons.checkCircle, color: Colors.orange),
              title: const Text('Quizzes Passed'),
              subtitle: const Text('Target: 3 quizzes'),
              onTap: () => Navigator.pop(context, 'quizzes_passed'),
            ),
          ],
        ),
      ),
    );

    if (type != null && mounted) {
      int target = 0;
      if (type == 'study_time') target = 120;
      if (type == 'lessons_completed') target = 5;
      if (type == 'quizzes_passed') target = 3;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await widget.service.setWeeklyGoal(
          userId: userId,
          goalType: type,
          targetValue: target,
        );
        _loadGoals();
      }
    }
  }

  String _getGoalTitle(String type) {
    switch (type) {
      case 'study_time':
        return 'Study Time (min)';
      case 'lessons_completed':
        return 'Lessons Completed';
      case 'quizzes_passed':
        return 'Quizzes Passed';
      default:
        return 'Goal';
    }
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await widget.service.getWeeklyGoals();
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }
}
