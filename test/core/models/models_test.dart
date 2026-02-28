import 'package:flutter_test/flutter_test.dart';
// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('UserModel Tests', () {
    test('create user with valid data', () {
      final user = UserModel(
        id: 'user-123',
        name: 'John Doe',
        email: 'john@example.com',
        profileImageUrl: 'https://example.com/image.jpg',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      expect(user.id, 'user-123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.profileImageUrl, isNotNull);
    });

    test('toJson converts user to map', () {
      final user = UserModel(
        id: 'user-456',
        name: 'Jane Doe',
        email: 'jane@example.com',
      );

      final json = user.toJson();
      expect(json['id'], 'user-456');
      expect(json['name'], 'Jane Doe');
      expect(json['email'], 'jane@example.com');
    });

    test('fromJson creates user from map', () {
      final json = {
        'id': 'user-789',
        'name': 'Bob Smith',
        'email': 'bob@example.com',
        'profileImageUrl': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-789');
      expect(user.name, 'Bob Smith');
      expect(user.email, 'bob@example.com');
    });

    test('user equality works correctly', () {
      final user1 = UserModel(
        id: 'user-1',
        name: 'Same User',
        email: 'same@example.com',
      );

      final user2 = UserModel(
        id: 'user-1',
        name: 'Same User',
        email: 'same@example.com',
      );

      expect(user1, equals(user2));
    });

    test('user with different ids are not equal', () {
      final user1 = UserModel(id: 'user-a', name: 'User', email: 'a@test.com');
      final user2 = UserModel(id: 'user-b', name: 'User', email: 'a@test.com');

      expect(user1, isNot(equals(user2)));
    });

    test('user copyWith creates modified copy', () {
      final original = UserModel(
        id: 'user-1',
        name: 'Original',
        email: 'original@example.com',
      );

      final modified = original.copyWith(name: 'Modified');

      expect(modified.id, 'user-1');
      expect(modified.name, 'Modified');
      expect(modified.email, 'original@example.com');
    });
  });

  group('MessageModel Tests', () {
    test('create message with valid content', () {
      final message = MessageModel(
        id: 'msg-1',
        content: 'Hello world',
        senderId: 'user-1',
        recipientId: 'user-2',
        timestamp: DateTime.now(),
      );

      expect(message.id, 'msg-1');
      expect(message.content, 'Hello world');
      expect(message.senderId, 'user-1');
      expect(message.recipientId, 'user-2');
    });

    test('message toJson serialization', () {
      final message = MessageModel(
        id: 'msg-2',
        content: 'Test message',
        senderId: 'user-a',
        recipientId: 'user-b',
        timestamp: DateTime(2026, 3, 10),
      );

      final json = message.toJson();
      expect(json['id'], 'msg-2');
      expect(json['content'], 'Test message');
      expect(json['senderId'], 'user-a');
    });

    test('message fromJson deserialization', () {
      final json = {
        'id': 'msg-3',
        'content': 'Deserialized',
        'senderId': 'sender',
        'recipientId': 'recipient',
        'timestamp': '2026-03-10T00:00:00.000Z',
        'isRead': false,
      };

      final message = MessageModel.fromJson(json);
      expect(message.content, 'Deserialized');
      expect(message.isRead, isFalse);
    });

    test('mark message as read', () {
      final original = MessageModel(
        id: 'msg-4',
        content: 'Unread',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      expect(original.isRead, isFalse);

      final read = original.copyWith(isRead: true);
      expect(read.isRead, isTrue);
    });

    test('archive message', () {
      final message = MessageModel(
        id: 'msg-5',
        content: 'To archive',
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      final archived = message.copyWith(isArchived: true);
      expect(archived.isArchived, isTrue);
    });
  });

  group('CourseModel Tests', () {
    test('create course with valid data', () {
      final course = CourseModel(
        id: 'course-1',
        title: 'Flutter Basics',
        description: 'Learn Flutter',
        instructorId: 'instructor-1',
        createdAt: DateTime.now(),
      );

      expect(course.id, 'course-1');
      expect(course.title, 'Flutter Basics');
      expect(course.description, 'Learn Flutter');
    });

    test('course toJson serialization', () {
      final course = CourseModel(
        id: 'course-2',
        title: 'Advanced Dart',
        description: 'Deep dive',
        instructorId: 'instructor-2',
      );

      final json = course.toJson();
      expect(json['title'], 'Advanced Dart');
      expect(json['instructorId'], 'instructor-2');
    });

    test('course fromJson deserialization', () {
      final json = {
        'id': 'course-3',
        'title': 'Web Development',
        'description': 'Web with Flutter',
        'instructorId': 'instructor-3',
        'createdAt': '2026-03-10T00:00:00.000Z',
      };

      final course = CourseModel.fromJson(json);
      expect(course.title, 'Web Development');
    });

    test('course with lessons', () {
      final course = CourseModel(
        id: 'course-4',
        title: 'Multi-lesson Course',
        description: 'With lessons',
        instructorId: 'instructor-1',
        lessons: [
          {'id': 'lesson-1', 'title': 'Intro'},
          {'id': 'lesson-2', 'title': 'Advanced'},
        ],
      );

      expect(course.lessons, isNotNull);
      expect(course.lessons!.length, 2);
    });

    test('course enrollment count', () {
      final course = CourseModel(
        id: 'course-5',
        title: 'Popular Course',
        description: 'Many students',
        instructorId: 'instructor-1',
        enrollmentCount: 150,
      );

      expect(course.enrollmentCount, 150);
    });
  });

  group('Model Validation Tests', () {
    test('user email validation', () {
      expect(
        () => UserModel(
          id: 'user-1',
          name: 'Test',
          email: 'invalid-email',
        ),
        throwsException,
      );
    });

    test('message content cannot be empty', () {
      expect(
        () => MessageModel(
          id: 'msg-1',
          content: '',
          senderId: 'user-1',
          recipientId: 'user-2',
        ),
        throwsException,
      );
    });

    test('course title is required', () {
      expect(
        () => CourseModel(
          id: 'course-1',
          title: '',
          description: 'desc',
          instructorId: 'inst-1',
        ),
        throwsException,
      );
    });
  });

  group('Model Edge Cases', () {
    test('user with null profile image', () {
      final user = UserModel(
        id: 'user-1',
        name: 'No Image',
        email: 'test@example.com',
        profileImageUrl: null,
      );

      expect(user.profileImageUrl, isNull);
    });

    test('message with very long content', () {
      final longText = 'a' * 10000;
      final message = MessageModel(
        id: 'msg-1',
        content: longText,
        senderId: 'user-1',
        recipientId: 'user-2',
      );

      expect(message.content.length, 10000);
    });

    test('course with unicode characters', () {
      final course = CourseModel(
        id: 'course-1',
        title: 'Курс по Flutter 🚀',
        description: '学习 Flutter',
        instructorId: 'instructor-1',
      );

      expect(course.title.contains('🚀'), isTrue);
    });
  });
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final DateTime? createdAt;
  final List<Map<String, dynamic>>? lessons;
  final int? enrollmentCount;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    this.createdAt,
    this.lessons,
    this.enrollmentCount,
  }) {
    if (title.isEmpty) {
      throw Exception('Course title is required');
    }
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? instructorId,
    DateTime? createdAt,
    List<Map<String, dynamic>>? lessons,
    int? enrollmentCount,
  }) =>
      CourseModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        instructorId: instructorId ?? this.instructorId,
        createdAt: createdAt ?? this.createdAt,
        lessons: lessons ?? this.lessons,
        enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'instructorId': instructorId,
        'createdAt': createdAt?.toIso8601String(),
        'enrollmentCount': enrollmentCount,
      };

  static CourseModel fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        instructorId: json['instructorId'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class MessageModel {
  final String id;
  final String content;
  final String senderId;
  final String recipientId;
  final DateTime? timestamp;
  final bool isRead;
  final bool isArchived;

  MessageModel({
    required this.id,
    required this.content,
    required this.senderId,
    required this.recipientId,
    this.timestamp,
    this.isRead = false,
    this.isArchived = false,
  }) {
    if (content.isEmpty) {
      throw Exception('Message content cannot be empty');
    }
  }

  MessageModel copyWith({
    String? id,
    String? content,
    String? senderId,
    String? recipientId,
    DateTime? timestamp,
    bool? isRead,
    bool? isArchived,
  }) =>
      MessageModel(
        id: id ?? this.id,
        content: content ?? this.content,
        senderId: senderId ?? this.senderId,
        recipientId: recipientId ?? this.recipientId,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
        isArchived: isArchived ?? this.isArchived,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'senderId': senderId,
        'recipientId': recipientId,
        'timestamp': timestamp?.toIso8601String(),
        'isRead': isRead,
        'isArchived': isArchived,
      };

  static MessageModel fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        content: json['content'] as String,
        senderId: json['senderId'] as String,
        recipientId: json['recipientId'] as String,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
        isRead: json['isRead'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
      );
}

// import 'package:verasso/core/models/user_model.dart';
// import 'package:verasso/core/models/message_model.dart';
// import 'package:verasso/core/models/course_model.dart';

// ---------------------------------------------------------------------------
// Stub Models (replace with real imports when the production models exist)
// ---------------------------------------------------------------------------

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  }) {
    if (!email.contains('@')) {
      throw Exception('Invalid email format');
    }
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profileImageUrl': profileImageUrl,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static UserModel fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
