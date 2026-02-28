import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/learning/data/collaboration_models.dart';
import 'package:verasso/features/learning/data/collaboration_repository.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/features/learning/learning_dashboard.dart';
import 'package:verasso/features/learning/presentation/widgets/upcoming_events_carousel.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../mocks.dart';

void main() {
  late MockCollaborationRepository mockCollaborationRepository;
  late MockCourseRepository mockCourseRepository;

  setUp(() {
    mockCollaborationRepository = MockCollaborationRepository();
    mockCourseRepository = MockCourseRepository();
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        collaborationRepositoryProvider
            .overrideWithValue(mockCollaborationRepository),
        courseRepositoryProvider.overrideWithValue(mockCourseRepository),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
        upcomingEventsProvider.overrideWith((ref) => Future.value([])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LearningDashboard(),
      ),
    );
  }

  group('LearningDashboard Widget Tests', () {
    testWidgets('renders Learning Hub title and main sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Learning Hub'), findsOneWidget);
      expect(find.text('Study Groups'), findsOneWidget);
      expect(find.text('Resource Library'), findsOneWidget);
      expect(find.text('Digital Courses'), findsOneWidget);
      expect(find.text('Mentors'), findsOneWidget);
    });

    testWidgets('renders active daily challenge when available',
        (WidgetTester tester) async {
      final challenge = DailyChallenge(
        id: '1',
        title: 'Physics Challenge',
        subject: 'Physics',
        content: 'Solve the motion equation.',
        rewardPoints: 20,
        createdAt: DateTime.now(),
      );

      mockCollaborationRepository.getActiveChallengesStub =
          () async => [challenge];

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('DAILY CHALLENGE - Physics'), findsOneWidget);
      expect(find.text('Physics Challenge'), findsOneWidget);
      expect(find.text('Complete & Earn 20 Karma'), findsOneWidget);
    });

    testWidgets('renders in-progress enrollments', (WidgetTester tester) async {
      final enrollment = Enrollment(
        id: 'e1',
        studentId: 's1',
        courseId: 'c1',
        courseTitle: 'Dart Mastery',
        progressPercent: 45,
        enrolledAt: DateTime.now(),
      );

      mockCourseRepository.getMyEnrollmentsStub = () async => [enrollment];

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('Dart Mastery'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });
  });
}
