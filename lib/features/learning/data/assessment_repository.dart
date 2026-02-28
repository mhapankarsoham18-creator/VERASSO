import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'assessment_models.dart';

/// Provider for the [AssessmentRepository].
final assessmentRepositoryProvider = Provider((ref) => AssessmentRepository());

/// Provider for fetching certificates earned by a user.
final userCertificatesProvider =
    FutureProvider.family<List<Certificate>, String>((ref, userId) {
  return ref.watch(assessmentRepositoryProvider).getStudentCertificates(userId);
});

/// Repository for managing assessments, including quizzes, questions, and certificates.
class AssessmentRepository {
  final SupabaseClient _client;

  /// Creates an [AssessmentRepository] instance.
  AssessmentRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // --- Quiz Management ---

  /// Retrieves the best score for a student on a specific quiz.
  Future<int> getBestQuizScore(String studentId, String quizId) async {
    try {
      final response = await _client
          .from('quiz_attempts')
          .select('score')
          .eq('student_id', studentId)
          .eq('quiz_id', quizId)
          .order('score', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['score'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Retrieves the quiz associated with a specific chapter.
  Future<Quiz?> getQuizForChapter(String chapterId) async {
    final response = await _client
        .from('quizzes')
        .select()
        .eq('chapter_id', chapterId)
        .maybeSingle();

    return response != null ? Quiz.fromJson(response) : null;
  }

  /// Retrieves the quiz associated with a specific course (not tied to a chapter).
  Future<Quiz?> getQuizForCourse(String courseId) async {
    final response = await _client
        .from('quizzes')
        .select()
        .eq('course_id', courseId)
        .filter('chapter_id', 'is', null)
        .maybeSingle();

    return response != null ? Quiz.fromJson(response) : null;
  }

  // --- Certificate Management ---

  /// Retrieves all questions associated with a specific quiz.
  Future<List<Question>> getQuizQuestions(String quizId) async {
    final response =
        await _client.from('questions').select().eq('quiz_id', quizId);

    return (response as List).map((json) => Question.fromJson(json)).toList();
  }

  /// Retrieves all certificates earned by a specific student.
  Future<List<Certificate>> getStudentCertificates(String studentId) async {
    final response = await _client
        .from('certificates')
        .select('*, courses:course_id(title)')
        .eq('student_id', studentId)
        .order('issued_at', ascending: false);

    return (response as List)
        .map((json) => Certificate.fromJson(json))
        .toList();
  }

  /// Checks if a student already has a certificate for a specific course.
  Future<bool> hasCertificateForCourse(
      String studentId, String courseId) async {
    final response = await _client
        .from('certificates')
        .select('id')
        .eq('student_id', studentId)
        .eq('course_id', courseId)
        .maybeSingle();

    return response != null;
  }

  /// Issues a certificate to a student for completing a course.
  Future<void> issueCertificate(String studentId, String courseId) async {
    await _client.from('certificates').insert({
      'student_id': studentId,
      'course_id': courseId,
      'issued_at': DateTime.now().toIso8601String(),
    });
  }

  /// Saves a student's quiz results.
  Future<void> saveAssessmentResult(QuizAttempt attempt) async {
    try {
      await _client.from('quiz_attempts').insert(attempt.toJson());
    } catch (e) {
      throw Exception('Failed to save assessment result: $e');
    }
  }
}
