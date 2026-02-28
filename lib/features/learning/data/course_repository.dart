import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/features/learning/data/transaction_repository.dart';
import 'package:verasso/features/learning/data/transaction_service.dart';

import '../../../../core/services/supabase_service.dart';
import '../../gamification/services/gamification_event_bus.dart';
import '../../social/data/post_model.dart';
import 'course_models.dart';

/// Provider for the [CourseRepository] instance.
final courseRepositoryProvider = Provider((ref) {
  final txService = ref.watch(transactionServiceProvider);
  final eventBus = ref.watch(gamificationEventBusProvider);
  return CourseRepository(txService: txService, eventBus: eventBus);
});

/// Repository for managing courses, chapters, enrollments, and student progress.
class CourseRepository {
  final SupabaseClient _client;
  final TransactionService _txService;
  final GamificationEventBus? _eventBus;

  /// Creates a [CourseRepository] instance.
  CourseRepository({
    SupabaseClient? client,
    TransactionService? txService,
    GamificationEventBus? eventBus,
  })  : _client = client ?? SupabaseService.client,
        _txService = txService ?? TransactionService(TransactionRepository()),
        _eventBus = eventBus;

  /// Adds a new chapter to a course.
  Future<Chapter> addChapter({
    required String courseId,
    required String title,
    required String content,
    required int order,
  }) async {
    final chapter = Chapter(
      id: '', // Will be generated
      courseId: courseId,
      title: title,
      contentMarkdown: content,
      orderIndex: order,
      createdAt: DateTime.now(),
    );
    try {
      final response = await _client
          .from('chapters')
          .insert(chapter.toJson())
          .select()
          .single();
      return Chapter.fromJson(response);
    } catch (e) {
      AppLogger.info('Add chapter error: $e');
      throw Exception('Failed to add chapter: $e');
    }
  }

  /// Creates a new course and returns its generated ID.
  Future<String> createCourse(Course course) async {
    try {
      final response = await _client
          .from('courses')
          .insert(course.toJson())
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      AppLogger.info('Create course error: $e');
      throw Exception('Failed to create course: $e');
    }
  }

  /// Enrolls the current user in a course, processing payment if necessary.
  ///
  /// If [paymentId] is provided, it assumes the payment was already processed
  /// externally (e.g., via Razorpay) and proceeds to record the transaction.
  Future<void> enrollInCourse(String courseId, double price,
      {String? paymentId}) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) {
      throw Exception('Not logged in');
    }

    try {
      // 1. Process Transaction (Immutable Ledger)
      if (price > 0) {
        if (paymentId != null) {
          // Record external payment in the ledger
          final transaction = Transaction(
            id: '',
            userId: studentId,
            targetId: courseId,
            type: TransactionType.purchase,
            amount: -price,
            currency: 'INR',
            createdAt: DateTime.now(),
            metadata: {
              'category': 'course_purchase_external',
              'payment_id': paymentId,
            },
          );
          await _txService.recordTransaction(transaction);
        } else {
          // Process via internal credits
          final success = await _txService.processCoursePurchase(
              studentId, courseId, price);
          if (!success) {
            throw Exception('Insufficient credits or transaction failed');
          }
        }
      }

      // 2. Grant Access (Enrollment Record)
      await _client.from('enrollments').upsert({
        'student_id': studentId,
        'course_id': courseId,
      });

      // 3. Trigger gamification v2
      _eventBus?.track(GamificationAction.courseEnrolled, studentId,
          metadata: {'course_id': courseId});
    } catch (e) {
      AppLogger.info('Enroll error: $e');
      throw Exception('Failed to enroll in course: $e');
    }
  }

  /// Enrolls a student in a course.
  Future<Enrollment> enrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    try {
      final response = await _client
          .from('enrollments')
          .insert({
            'student_id': studentId,
            'course_id': courseId,
          })
          .select()
          .single();
      return Enrollment.fromJson(response);
    } catch (e) {
      AppLogger.info('Enroll student error: $e');
      throw Exception('Failed to enroll student: $e');
    }
  }

  /// Retrieves all chapters for a specific course, ordered by their index.
  Future<List<Chapter>> getChapters(String courseId) async {
    try {
      final response = await _client
          .from('chapters')
          .select('*')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      return (response as List).map((json) => Chapter.fromJson(json)).toList();
    } catch (e) {
      AppLogger.info('Get chapters error: $e');
      return [];
    }
  }

  /// Retrieves a course by its [id].
  Future<Course> getCourse(String id) async {
    try {
      final response = await _client
          .from('courses')
          .select('*, profiles:creator_id(full_name)')
          .eq('id', id)
          .single();
      return Course.fromJson(response);
    } catch (e) {
      AppLogger.info('Get course error: $e');
      throw Exception('Failed to get course: $e');
    }
  }

  // --- Enrollment & Progress ---

  /// Alias for [getChapters] for test compatibility.
  Future<List<Chapter>> getCourseChapters(String courseId) =>
      getChapters(courseId);

  /// Retrieves the completion percentage for a student in a course.
  Future<double> getCourseCompletion({
    required String courseId,
    required String studentId,
  }) async {
    try {
      final enrollment = await _client
          .from('enrollments')
          .select('progress_percent')
          .eq('course_id', courseId)
          .eq('student_id', studentId)
          .maybeSingle();
      return (enrollment?['progress_percent'] ?? 0).toDouble();
    } catch (e) {
      AppLogger.info('Get completion error: $e');
      return 0.0;
    }
  }

  /// Retrieves all courses created by a specific instructor.
  Future<List<Course>> getCoursesByInstructor(String instructorId) async {
    try {
      final response = await _client
          .from('courses')
          .select('*')
          .eq('creator_id', instructorId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      AppLogger.info('Get instructor courses error: $e');
      return [];
    }
  }

  /// Retrieves all students enrolled in a specific course.
  Future<List<String>> getEnrolledStudents(String courseId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('student_id')
          .eq('course_id', courseId);
      return (response as List).map((e) => e['student_id'] as String).toList();
    } catch (e) {
      AppLogger.info('Get enrolled students error: $e');
      return [];
    }
  }

  /// Retrieves the enrollment details for a specific course for the current user.
  Future<Enrollment?> getEnrollmentForCourse(String courseId) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) return null;

    try {
      final response = await _client
          .from('enrollments')
          .select()
          .eq('student_id', studentId)
          .eq('course_id', courseId)
          .maybeSingle();

      return response != null ? Enrollment.fromJson(response) : null;
    } catch (e) {
      AppLogger.info('Get enrollment error: $e');
      return null;
    }
  }

  /// Retrieves all courses created by the current user.
  Future<List<Course>> getMyCreatedCourses() async {
    final creatorId = _client.auth.currentUser?.id;
    if (creatorId == null) return [];

    try {
      final response = await _client
          .from('courses')
          .select('*')
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      AppLogger.info('Get my courses error: $e');
      return [];
    }
  }

  // --- Course Discovery & Management ---

  /// Retrieves all courses the current user is enrolled in.
  Future<List<Enrollment>> getMyEnrollments() async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) return [];

    try {
      final response = await _client
          .from('enrollments')
          .select('*, courses:course_id(title, cover_url)')
          .eq('student_id', studentId);

      return (response as List)
          .map((json) => Enrollment.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.info('Get my enrollments error: $e');
      return [];
    }
  }

  /// Retrieves the progress percentage for a specific course for the current user.
  Future<int> getProgressPercent(String courseId) async {
    final enrollment = await getEnrollmentForCourse(courseId);
    return enrollment?.progressPercent ?? 0;
  }

  /// Retrieves all courses that are marked as published.
  Future<List<Course>> getPublishedCourses() async {
    try {
      final response = await _client
          .from('courses')
          .select('*, profiles:creator_id(full_name)')
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      AppLogger.info('Get published courses error: $e');
      return [];
    }
  }

  /// Retrieves a specific simulation by its ID.
  Future<Post?> getSimulation(String id) async {
    try {
      final response = await _client
          .from('posts')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('id', id)
          .eq('type', 'simulation')
          .maybeSingle();

      return response != null ? Post.fromJson(response) : null;
    } catch (e) {
      AppLogger.info('Get simulation error: $e');
      return null;
    }
  }

  /// Retrieves all simulations from the posts table.
  Future<List<Post>> getSimulations() async {
    try {
      final response = await _client
          .from('posts')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('type', 'simulation')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      AppLogger.info('Get simulations error: $e');
      return [];
    }
  }

  /// Marks a chapter as complete for a student.
  Future<bool> markChapterComplete({
    required String chapterId,
    required String studentId,
  }) async {
    try {
      await _client.from('chapter_completions').upsert({
        'chapter_id': chapterId,
        'student_id': studentId,
        'completed_at': DateTime.now().toIso8601String(),
      });
      // Award XP for chapter (lesson) completion
      _eventBus?.track(GamificationAction.lessonCompleted, studentId,
          metadata: {'chapter_id': chapterId});
      return true;
    } catch (e) {
      AppLogger.info('Mark chapter complete error: $e');
      return false;
    }
  }

  /// Records progress or data for a simulation.
  Future<void> saveSimulationData(
      String postId, Map<String, dynamic> data) async {
    try {
      await _client.from('posts').update({
        'simulation_data': data,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', postId);
    } catch (e) {
      AppLogger.info('Save simulation data error: $e');
      throw Exception('Failed to save simulation data: $e');
    }
  }

  /// Searches courses whose title or description match the [query].
  Future<List<Course>> searchCourses(String query) async {
    try {
      final response = await _client
          .from('courses')
          .select('*, profiles:creator_id(full_name)')
          .eq('is_published', true)
          .textSearch('title', query, config: 'english')
          .limit(20);

      return (response as List).map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      AppLogger.info('Search courses error: $e');
      return [];
    }
  }

  // --- Simulations (Fetched from Posts table) ---

  /// Unenrolls a student from a course.
  Future<bool> unenrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    try {
      await _client
          .from('enrollments')
          .delete()
          .eq('course_id', courseId)
          .eq('student_id', studentId);
      return true;
    } catch (e) {
      AppLogger.info('Unenroll error: $e');
      return false;
    }
  }

  /// Updates the information of an existing course.
  Future<void> updateCourse(Course course) async {
    try {
      await _client.from('courses').update(course.toJson()).eq('id', course.id);
    } catch (e) {
      AppLogger.info('Update course error: $e');
      throw Exception('Failed to update course: $e');
    }
  }

  /// Updates a student's progress in a course based on completed chapters.
  Future<void> updateProgress(String enrollmentId,
      List<String> completedChapters, int totalChapters) async {
    final progress = (completedChapters.length / totalChapters * 100).toInt();

    try {
      await _client.from('enrollments').update({
        'completed_chapters': completedChapters,
        'progress_percent': progress,
        'completed_at':
            progress == 100 ? DateTime.now().toIso8601String() : null,
      }).eq('id', enrollmentId);
    } catch (e) {
      AppLogger.info('Update progress error: $e');
      throw Exception('Failed to update progress: $e');
    }
  }
}
