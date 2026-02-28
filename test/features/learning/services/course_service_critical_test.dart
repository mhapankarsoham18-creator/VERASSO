import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/data/course_repository.dart';

import '../../../mocks.dart';

void main() {
  late CourseRepository courseRepository;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    courseRepository = CourseRepository(client: mockSupabase);
  });

  tearDown(() {
    // Cleanup
  });

  group('Course Repository - Course Management', () {
    test('create course with valid data', () async {
      const title = 'Flutter Basics';
      const description = 'Learn Flutter from scratch';
      const creatorId = 'instructor-1';

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('courses', mockQueryBuilder);
      mockQueryBuilder.setResponse({
        'id': 'course-1',
        'title': title,
        'description': description,
        'creator_id': creatorId,
        'created_at': DateTime.now().toIso8601String(),
      });

      final courseToCreate = Course(
        id: '',
        title: title,
        description: description,
        creatorId: creatorId,
        createdAt: DateTime.now(),
      );

      final courseId = await courseRepository.createCourse(courseToCreate);

      expect(courseId, equals('course-1'));
    });

    test('retrieve course by ID', () async {
      const courseId = 'course-123';
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('courses', mockQueryBuilder);
      mockQueryBuilder.setResponse({
        'id': courseId,
        'title': 'Advanced Dart',
        'description': 'Deep dive into Dart',
        'creator_id': 'instructor-1',
        'created_at': DateTime.now().toIso8601String(),
      });

      final retrieved = await courseRepository.getCourse(courseId);
      expect(retrieved.id, equals(courseId));
      expect(retrieved.title, equals('Advanced Dart'));
    });

    test('list courses by instructor', () async {
      const instructorId = 'instructor-2';
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('courses', mockQueryBuilder);
      mockQueryBuilder.setResponse([
        {'id': 'c1', 'title': 'Course 1', 'creator_id': instructorId},
        {'id': 'c2', 'title': 'Course 2', 'creator_id': instructorId},
      ]);

      final courses =
          await courseRepository.getCoursesByInstructor(instructorId);
      expect(courses.length, equals(2));
    });
  });

  group('Course Repository - Chapters', () {
    test('add chapter to course', () async {
      const courseId = 'course-1';
      const chapterTitle = 'Introduction';
      const chapterContent = 'This is the first chapter';

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('chapters', mockQueryBuilder);
      mockQueryBuilder.setResponse({
        'id': 'chapter-1',
        'course_id': courseId,
        'title': chapterTitle,
        'content': chapterContent,
        'order_index': 1,
      });

      final chapter = await courseRepository.addChapter(
        courseId: courseId,
        title: chapterTitle,
        content: chapterContent,
        order: 1,
      );

      expect(chapter.courseId, equals(courseId));
      expect(chapter.title, equals(chapterTitle));
      expect(chapter.contentMarkdown, equals(chapterContent));
    });

    test('chapters are ordered correctly', () async {
      const courseId = 'course-1';
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('chapters', mockQueryBuilder);
      mockQueryBuilder.setResponse([
        {
          'id': 'ch1',
          'course_id': courseId,
          'title': 'Chapter 1',
          'order_index': 1
        },
        {
          'id': 'ch2',
          'course_id': courseId,
          'title': 'Chapter 2',
          'order_index': 2
        },
      ]);

      final chapters = await courseRepository.getChapters(courseId);
      expect(chapters[0].orderIndex, equals(1));
      expect(chapters[1].orderIndex, equals(2));
    });
  });

  group('Course Repository - Enrollment', () {
    test('enroll student in course', () async {
      const courseId = 'course-1';
      const studentId = 'student-1';

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('enrollments', mockQueryBuilder);
      mockQueryBuilder.setResponse({
        'id': 'enroll-1',
        'course_id': courseId,
        'student_id': studentId,
        'enrolled_at': DateTime.now().toIso8601String(),
      });

      final enrollment = await courseRepository.enrollStudent(
        courseId: courseId,
        studentId: studentId,
      );

      expect(enrollment.courseId, equals(courseId));
      expect(enrollment.studentId, equals(studentId));
    });

    test('get enrolled students', () async {
      const courseId = 'course-1';
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('enrollments', mockQueryBuilder);
      mockQueryBuilder.setResponse([
        {'student_id': 'student-1'},
        {'student_id': 'student-2'},
      ]);

      final students = await courseRepository.getEnrolledStudents(courseId);
      expect(students.length, equals(2));
      expect(students, contains('student-1'));
    });

    test('unenroll student from course', () async {
      const courseId = 'course-1';
      const studentId = 'student-3';

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('enrollments', mockQueryBuilder);

      final success = await courseRepository.unenrollStudent(
        courseId: courseId,
        studentId: studentId,
      );

      expect(success, isTrue);
    });
  });

  group('Course Repository - Progress Tracking', () {
    test('mark chapter as completed', () async {
      const chapterId = 'chapter-1';
      const studentId = 'student-4';

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('chapter_completions', mockQueryBuilder);

      final success = await courseRepository.markChapterComplete(
        chapterId: chapterId,
        studentId: studentId,
      );

      expect(success, isTrue);
    });

    test('get course completion percentage', () async {
      const courseId = 'course-1';
      const studentId = 'student-5';

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('enrollments', mockQueryBuilder);
      mockQueryBuilder.setResponse({
        'progress_percent': 75.0,
      });

      final completion = await courseRepository.getCourseCompletion(
        courseId: courseId,
        studentId: studentId,
      );

      expect(completion, equals(75.0));
    });
  });
}
