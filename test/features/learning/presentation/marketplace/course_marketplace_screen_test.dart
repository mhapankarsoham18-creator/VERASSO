import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/ui/shimmers/course_skeleton.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/presentation/marketplace/course_marketplace_screen.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';

import '../../../../mocks.dart';

void main() {
  testWidgets('CourseMarketplaceScreen shows skeleton while fetching',
      (tester) async {
    // Act
    await tester.pumpWidget(ProviderScope(
      overrides: [
        publishedCoursesProvider.overrideWithValue(const AsyncLoading()),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
      ],
      child: const MaterialApp(home: CourseMarketplaceScreen()),
    ));
    await tester.pump();

    // Assert
    expect(find.byType(CourseSkeleton), findsOneWidget);
  });

  testWidgets('CourseMarketplaceScreen shows courses when data is available',
      (tester) async {
    // Arrange
    final courses = [
      Course(
        id: '1',
        title: 'Flutter Basics',
        description: 'Learn Flutter',
        creatorId: 'c1',
        price: 0,
        createdAt: DateTime.now(),
      ),
    ];

    // Act
    await tester.pumpWidget(ProviderScope(
      overrides: [
        publishedCoursesProvider.overrideWithValue(AsyncData(courses)),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
      ],
      child: const MaterialApp(home: CourseMarketplaceScreen()),
    ));
    await tester.pump();

    // Assert
    expect(find.text('Flutter Basics'), findsOneWidget);
  });

  testWidgets('CourseMarketplaceScreen shows empty state when no courses',
      (tester) async {
    // Act
    await tester.pumpWidget(ProviderScope(
      overrides: [
        publishedCoursesProvider.overrideWithValue(const AsyncData([])),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
      ],
      child: const MaterialApp(home: CourseMarketplaceScreen()),
    ));
    await tester.pump();

    // Assert
    expect(find.textContaining('No courses available yet'), findsOneWidget);
  });

  testWidgets('CourseMarketplaceScreen shows error state on failure',
      (tester) async {
    // Act
    await tester.pumpWidget(ProviderScope(
      overrides: [
        publishedCoursesProvider.overrideWithValue(
            AsyncError('Failed to load courses', StackTrace.empty)),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
      ],
      child: const MaterialApp(home: CourseMarketplaceScreen()),
    ));
    await tester.pump();

    // Assert
    expect(
        find.textContaining('Error: Failed to load courses'), findsOneWidget);
  });
}
