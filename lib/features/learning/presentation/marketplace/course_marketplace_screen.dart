import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/course_skeleton.dart';

import '../../data/course_models.dart';
import '../../data/course_repository.dart';
import 'course_player_screen.dart'; // To be created

// Local provider removed to use the central one in course_repository.dart

/// Future provider for fetching all published courses.
final publishedCoursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(courseRepositoryProvider).getPublishedCourses();
});

/// A screen that displays a marketplace for discovering and enrolling in digital courses.
class CourseMarketplaceScreen extends ConsumerWidget {
  /// Creates a [CourseMarketplaceScreen] instance.
  const CourseMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(publishedCoursesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Digital Courses'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {}, // Search logic
          ),
        ],
      ),
      body: LiquidBackground(
        child: coursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return const Center(
                  child: Text('No courses available yet. Check back soon!'));
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) =>
                  _buildCourseCard(context, ref, courses[index]),
            );
          },
          loading: () => const CourseSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, WidgetRef ref, Course course) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CoursePlayerScreen(course: course))),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: course.coverUrl != null
                    ? Image.network(course.coverUrl!, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                size: 40, color: Colors.white24))
                    : Container(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        child: const Icon(LucideIcons.bookOpen,
                            color: Colors.blueAccent, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              course.creatorName ?? 'Verified Instructor',
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.price > 0
                      ? '\$${course.price.toStringAsFixed(0)}'
                      : 'FREE',
                  style: TextStyle(
                    color: course.price > 0
                        ? Colors.greenAccent
                        : Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Icon(LucideIcons.arrowRightCircle,
                    size: 16, color: Colors.white30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
