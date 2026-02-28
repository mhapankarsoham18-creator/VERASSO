import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/news/domain/news_model.dart';

void main() {
  group('NewsArticle Model Tests', () {
    final now = DateTime.now();
    final sampleJson = {
      'id': 'art-1',
      'author_id': 'user-1',
      'title': 'Quantum Computing 101',
      'description': 'An intro to qubits',
      'content': {'ops': []},
      'latex_content': r'E = mc^2',
      'subject': 'Physics',
      'audience_type': 'Students',
      'article_type': 'concept_explainer',
      'reading_time': 8,
      'image_url': 'https://example.com/image.png',
      'is_featured': true,
      'is_published': true,
      'upvotes_count': 42,
      'comments_count': 7,
      'featured_at': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'profiles': {
        'full_name': 'Dr. Smith',
        'avatar_url': 'https://example.com/avatar.png',
        'journalist_level': 'senior',
      },
    };

    test('fromJson should create valid NewsArticle', () {
      final article = NewsArticle.fromJson(sampleJson);

      expect(article.id, 'art-1');
      expect(article.title, 'Quantum Computing 101');
      expect(article.subject, 'Physics');
      expect(article.isFeatured, true);
      expect(article.isPublished, true);
      expect(article.readingTime, 8);
      expect(article.authorName, 'Dr. Smith');
      expect(article.authorBadge, 'senior');
      expect(article.upvotesCount, 42);
    });

    test('fromJson should handle missing optional fields', () {
      final minimalJson = {
        'id': 'art-2',
        'author_id': 'user-2',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final article = NewsArticle.fromJson(minimalJson);

      expect(article.title, 'No Title');
      expect(article.subject, 'General');
      expect(article.audienceType, 'All');
      expect(article.readingTime, 5);
      expect(article.isFeatured, false);
      expect(article.isPublished, false);
      expect(article.content, isEmpty);
    });

    test('toJson should produce valid map', () {
      final article = NewsArticle.fromJson(sampleJson);
      final json = article.toJson();

      expect(json['id'], 'art-1');
      expect(json['title'], 'Quantum Computing 101');
      expect(json['subject'], 'Physics');
      expect(json['profiles']['full_name'], 'Dr. Smith');
    });

    test('toJson -> fromJson roundtrip should preserve data', () {
      final original = NewsArticle.fromJson(sampleJson);
      final roundtripped = NewsArticle.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.title, original.title);
      expect(roundtripped.subject, original.subject);
      expect(roundtripped.isFeatured, original.isFeatured);
      expect(roundtripped.authorName, original.authorName);
    });

    test('copyWith should override specific fields', () {
      final article = NewsArticle.fromJson(sampleJson);
      final updated = article.copyWith(
        title: 'Updated Title',
        isFeatured: false,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.isFeatured, false);
      expect(updated.subject, 'Physics'); // unchanged
    });
  });

  group('JournalistBadge Tests', () {
    test('fromString should return correct badge', () {
      expect(JournalistBadge.fromString('junior'), JournalistBadge.junior);
      expect(JournalistBadge.fromString('Senior'), JournalistBadge.senior);
      expect(JournalistBadge.fromString('EDITOR'), JournalistBadge.editor);
    });

    test('fromString should return none for null', () {
      expect(JournalistBadge.fromString(null), JournalistBadge.none);
    });

    test('fromString should return none for unknown value', () {
      expect(JournalistBadge.fromString('invalid'), JournalistBadge.none);
    });
  });
}
