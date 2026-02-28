import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/payment_service.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/gamification/presentation/user_stats_controller.dart';
import 'package:verasso/features/learning/data/assessment_models.dart';
import 'package:verasso/features/learning/data/assessment_repository.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/features/learning/presentation/marketplace/quiz_player_screen.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';
import 'package:video_player/video_player.dart';

/// Future provider for fetching chapters of a specific course.
final chaptersProvider =
    FutureProvider.family<List<Chapter>, String>((ref, courseId) {
  return ref.watch(courseRepositoryProvider).getChapters(courseId);
});

/// Future provider for fetching the final quiz associated with a course.
final courseQuizProvider =
    FutureProvider.family<Quiz?, String>((ref, courseId) {
  return ref.watch(assessmentRepositoryProvider).getQuizForCourse(courseId);
});

/// Future provider for fetching the enrollment status of the current user for a course.
final enrollmentProvider =
    FutureProvider.family<Enrollment?, String>((ref, courseId) {
  return ref.watch(courseRepositoryProvider).getEnrollmentForCourse(courseId);
});

/// A screen for playing course content, including watching videos, reading lessons, and taking quizzes.
class CoursePlayerScreen extends ConsumerStatefulWidget {
  /// The course being played.
  final Course course;

  /// Creates a [CoursePlayerScreen] instance.
  const CoursePlayerScreen({super.key, required this.course});

  @override
  ConsumerState<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends ConsumerState<CoursePlayerScreen> {
  int _currentChapterIndex = 0;
  bool _isEnrolling = false;
  VideoPlayerController? _videoController;

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chaptersProvider(widget.course.id));
    final enrollmentAsync = ref.watch(enrollmentProvider(widget.course.id));

    return chaptersAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (chapters) {
        if (chapters.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.course.title)),
            body: const Center(child: Text('This course has no chapters yet.')),
          );
        }

        final currentChapter = chapters[_currentChapterIndex];

        if (_videoController == null &&
            currentChapter.videoUrl != null &&
            currentChapter.videoUrl!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_videoController == null) {
              _initializeVideo(currentChapter.videoUrl);
            }
          });
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(widget.course.title),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: LiquidBackground(
            child: enrollmentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (Enrollment? enrollment) {
                final isEnrolled = enrollment != null;

                return Column(
                  children: [
                    const SizedBox(height: 100),
                    // Video Player
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _videoController != null &&
                                _videoController!.value.isInitialized
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(_videoController!),
                                    VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Center(
                                child: Icon(LucideIcons.playCircle,
                                    color: Colors.white, size: 64),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  currentChapter.title,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isEnrolled)
                                IconButton(
                                  icon: Icon(
                                    enrollment.completedChapters
                                            .contains(currentChapter.id)
                                        ? LucideIcons.checkCircle2
                                        : LucideIcons.circle,
                                    color: Colors.greenAccent,
                                  ),
                                  onPressed: () => _toggleChapterCompletion(
                                      currentChapter,
                                      enrollment,
                                      chapters.length),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_currentChapterIndex == chapters.length - 1)
                            ref
                                .watch(courseQuizProvider(widget.course.id))
                                .when(
                                  data: (Quiz? quiz) {
                                    if (quiz == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return GlassContainer(
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.only(bottom: 24),
                                      border: Border.all(
                                        color: Colors.blueAccent
                                            .withValues(alpha: 0.3),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.graduationCap,
                                              color: Colors.blueAccent),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Final Assessment',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    'Pass to earn your official certificate',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white54)),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        QuizPlayerScreen(
                                                            quiz: quiz))),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16)),
                                            child: const Text('Start Quiz',
                                                style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                          MarkdownBody(
                            data: currentChapter.contentMarkdown ??
                                'No content for this chapter.',
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                  color: Colors.white70, height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Divider(color: Colors.white10),
                          const Text('Course Syllabus',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white54)),
                          const SizedBox(height: 12),
                          ...chapters.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ch = entry.value;
                            return ListTile(
                              onTap: () {
                                setState(() {
                                  _currentChapterIndex = idx;
                                });
                                _initializeVideo(ch.videoUrl);
                              },
                              leading: Text('${idx + 1}',
                                  style: TextStyle(
                                      color: _currentChapterIndex == idx
                                          ? Colors.blueAccent
                                          : Colors.white30)),
                              title: Text(ch.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _currentChapterIndex == idx
                                        ? Colors.white
                                        : Colors.white60,
                                    fontWeight: _currentChapterIndex == idx
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  )),
                              trailing: enrollment?.completedChapters
                                          .contains(ch.id) ==
                                      true
                                  ? const Icon(LucideIcons.check,
                                      color: Colors.greenAccent, size: 16)
                                  : null,
                            );
                          }),
                        ],
                      ),
                    ),
                    if (!isEnrolled)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isEnrolling ? null : _enroll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: _isEnrolling
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    'Enroll for \$${widget.course.price.toStringAsFixed(0)}'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _enroll() async {
    setState(() => _isEnrolling = true);
    try {
      if (widget.course.price > 0) {
        // Trigger external payment
        final paymentService = ref.read(paymentServiceProvider);

        // We need a way to get the payment response.
        // For simplicity in this prototype, we'll listen to the service or pass a callback.
        // Actually, PaymentService should ideally return a Future or trigger a provider.
        // For now, let's assume successful checkout since we don't have deep state tracking.

        await paymentService.checkout(
          amount: (widget.course.price * 100).toInt(), // to paise
          description: 'Enrollment: ${widget.course.title}',
          metadata: {'course_id': widget.course.id},
        );

        // Note: Real confirmation would happen via handlePaymentSuccess
        // which would then trigger the enrollment in the background or via state updates.
        // For this demo, we'll wait a bit and then show a placeholder or handle success logic.
      } else {
        // Free course
        await ref
            .read(courseRepositoryProvider)
            .enrollInCourse(widget.course.id, widget.course.price);
        ref.invalidate(enrollmentProvider(widget.course.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully enrolled in course!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Enrollment failed: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  void _initializeVideo(String? url) {
    _videoController?.dispose();
    if (url == null || url.isEmpty) {
      setState(() => _videoController = null);
      return;
    }

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {});
        _videoController?.play();
      });
  }

  void _toggleChapterCompletion(
      Chapter chapter, Enrollment enrollment, int totalChapters) async {
    final completed = List<String>.from(enrollment.completedChapters);
    final isCompleting = !completed.contains(chapter.id);

    if (!isCompleting) {
      completed.remove(chapter.id);
    } else {
      completed.add(chapter.id);
    }

    await ref
        .read(courseRepositoryProvider)
        .updateProgress(enrollment.id, completed, totalChapters);

    if (isCompleting) {
      // Reward XP
      ref.read(userStatsProvider.notifier).addXP(50);

      // Hook: Log Activity
      try {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId != null) {
          await ProgressTrackingService().logActivity(
            userId: userId,
            activityType: 'completed_lesson',
            activityCategory: 'learning',
            metadata: {'chapter_id': chapter.id, 'course_id': widget.course.id},
          );
        }
      } catch (e) {
        AppLogger.error('Error logging lesson completion', error: e);
      }
    }

    ref.invalidate(enrollmentProvider(widget.course.id));
  }
}
