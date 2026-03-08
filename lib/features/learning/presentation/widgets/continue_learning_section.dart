import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/l10n/app_localizations.dart';

/// Provider that fetches the current user's enrollments.
final myEnrollmentsProvider = FutureProvider<List<Enrollment>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getMyEnrollments();
});

/// A horizontal scrolling list of in-progress courses.
class ContinueLearningSection extends ConsumerWidget {
  const ContinueLearningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(myEnrollmentsProvider).when(
      data: (enrollments) {
        final inProgress =
            enrollments.where((e) => e.progressPercent < 100).toList();
        if (inProgress.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context)!.continueLearning,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: inProgress.length,
                itemBuilder: (context, index) {
                  final enroll = inProgress[index];
                  return Semantics(
                    label:
                        'Continue course: ${enroll.courseTitle}, ${enroll.progressPercent} percent complete',
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              enroll.courseTitle ?? 'Course',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: enroll.progressPercent / 100,
                              backgroundColor: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            Text(
                              '${enroll.progressPercent}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
