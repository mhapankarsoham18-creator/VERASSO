/// Represents a certificate awarded to a student upon course completion.
class Certificate {
  /// Unique identifier of the certificate.
  final String id;

  /// The ID of the student who earned the certificate.
  final String studentId;

  /// The ID of the course the certificate is for.
  final String courseId;

  /// The date the certificate was issued.
  final DateTime issuedAt;

  /// The URL where the certificate can be viewed or downloaded.
  final String? certificateUrl;

  /// Unique code for verifying the authenticity of the certificate.
  final String verificationCode;

  /// Additional metadata associated with the certificate.
  final Map<String, dynamic> metadata;

  // Joined fields
  /// The title of the course (optional, populated via joins).
  final String? courseTitle;

  /// The name of the student (optional, populated via joins).
  final String? studentName;

  /// Creates a [Certificate].
  Certificate({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.issuedAt,
    this.certificateUrl,
    required this.verificationCode,
    this.metadata = const {},
    this.courseTitle,
    this.studentName,
  });

  /// Creates a [Certificate] from a JSON-compatible map.
  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'],
      studentId: json['student_id'],
      courseId: json['course_id'],
      issuedAt: DateTime.parse(json['issued_at']),
      certificateUrl: json['certificate_url'],
      verificationCode: json['verification_code'],
      metadata: json['metadata'] ?? {},
      courseTitle: json['courses']?['title'],
      studentName: json['profiles']?['full_name'],
    );
  }
}

/// Represents a single question within a quiz.
class Question {
  /// Unique identifier of the question.
  final String id;

  /// The ID of the quiz this question belongs to.
  final String quizId;

  /// The text content of the question.
  final String questionText;

  /// List of multiple-choice options.
  final List<String> options;

  /// The 0-based index of the correct option in the [options] list.
  final int correctOptionIndex;

  /// Creates a [Question].
  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });

  /// Creates a [Question] from a JSON-compatible map.
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correct_option_index'],
    );
  }

  /// Converts the [Question] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'question_text': questionText,
      'options': options,
      'correct_option_index': correctOptionIndex,
    };
  }
}

/// Represents a quiz associated with a course or chapter.
class Quiz {
  /// Unique identifier of the quiz.
  final String id;

  /// The ID of the course this quiz belongs to.
  final String courseId;

  /// The optional ID of a specific chapter this quiz covers.
  final String? chapterId;

  /// Title of the quiz.
  final String title;

  /// The score (0-100) required to pass the quiz.
  final int passingScore;

  /// The date when the quiz was created.
  final DateTime createdAt;

  /// Creates a [Quiz].
  Quiz({
    required this.id,
    required this.courseId,
    this.chapterId,
    required this.title,
    this.passingScore = 80,
    required this.createdAt,
  });

  /// Creates a [Quiz] from a JSON-compatible map.
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      courseId: json['course_id'],
      chapterId: json['chapter_id'],
      title: json['title'],
      passingScore: json['passing_score'] ?? 80,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [Quiz] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'chapter_id': chapterId,
      'title': title,
      'passing_score': passingScore,
    };
  }
}

/// Represents a student's attempt at a quiz.
class QuizAttempt {
  /// Unique identifier of the attempt.
  final String id;

  /// The ID of the student who took the quiz.
  final String studentId;

  /// The ID of the quiz taken.
  final String quizId;

  /// The score achieved (0-100).
  final int score;

  /// Whether the student passed the quiz.
  final bool isPassed;

  /// The student's answers (question_id -> selected_option_index).
  final Map<String, int> answers;

  /// The date and time when the quiz was taken.
  final DateTime createdAt;

  /// Creates a [QuizAttempt].
  QuizAttempt({
    required this.id,
    required this.studentId,
    required this.quizId,
    required this.score,
    required this.isPassed,
    required this.answers,
    required this.createdAt,
  });

  /// Creates a [QuizAttempt] from a JSON-compatible map.
  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      studentId: json['student_id'],
      quizId: json['quiz_id'],
      score: json['score'],
      isPassed: json['is_passed'],
      answers: Map<String, int>.from(json['answers'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [QuizAttempt] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'quiz_id': quizId,
      'score': score,
      'is_passed': isPassed,
      'answers': answers,
    };
  }
}
