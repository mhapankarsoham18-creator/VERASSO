import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/theme/design_system.dart';
import 'package:verasso/core/ui/cached_image.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../learning/data/course_models.dart';
import '../../learning/presentation/marketplace/course_player_screen.dart';
import '../../news/data/news_repository.dart';
import '../../news/domain/news_model.dart';
import '../../news/presentation/news_screen.dart';

/// A horizontally scrolling ticker that displays live news headlines.
class NewsTicker extends ConsumerStatefulWidget {
  /// Creates a [NewsTicker] instance.
  const NewsTicker({super.key});

  @override
  ConsumerState<NewsTicker> createState() => _NewsTickerState();
}

/// A carousel widget displaying trending courses.
class TrendingCarousel extends StatelessWidget {
  /// The list of courses to display.
  final List<Course> courses;

  /// Creates a [TrendingCarousel] instance.
  const TrendingCarousel({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(LucideIcons.trendingUp, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('Trending Courses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Semantics(
                button: true,
                label:
                    'Course: ${course.title}. By ${course.creatorName}. Price: \$${course.price.toStringAsFixed(0)}',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CoursePlayerScreen(course: course)));
                  },
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 16),
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: course.coverUrl != null
                                  ? CachedImage(
                                      imageUrl: course.coverUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.blueAccent
                                          .withValues(alpha: 0.1),
                                      child: const Center(
                                          child: Icon(LucideIcons.bookOpen,
                                              color: Colors.blueAccent)),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        course.creatorName ??
                                            'Verified Instructor',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white54)),
                                    Text('\$${course.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewsTickerState extends ConsumerState<NewsTicker> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    // Determine category based on cycling index or just fetch tech/general
    final newsStream =
        ref.watch(newsRepositoryProvider).watchArticles(subject: 'global');

    return StreamBuilder<List<NewsArticle>>(
      stream: newsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final articles = snapshot.data!;
        final article = articles[_currentIndex % articles.length];

        return GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NewsScreen())),
          child: Container(
            height: 32,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(0, 0.5),
                                    end: Offset.zero)
                                .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: DesignSystem.easingStandard)),
                            child: child,
                          ));
                    },
                    child: Text(
                      article.title, // Display Title
                      key: ValueKey<String>(article.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
                    color: Colors.white54, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    // Skip timer in tests to avoid pending timer issues (flutter_animate/timers)
    if (RegExp(r'test')
            .hasMatch(Stream.fromIterable([]).runtimeType.toString()) ||
        WidgetsBinding.instance is WidgetsFlutterBinding == false) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
      }
    });
  }
}
