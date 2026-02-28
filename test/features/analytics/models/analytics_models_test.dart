import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/analytics/models/analytics_models.dart';

void main() {
  group('ContentStats', () {
    test('fromJson creates instance with all fields', () {
      final json = {
        'content_id': 'post-1',
        'content_type': 'post',
        'views_count': 100,
        'likes_count': 25,
        'comments_count': 10,
        'shares_count': 5,
        'engagement_rate': 0.4,
      };

      final stats = ContentStats.fromJson(json);

      expect(stats.contentId, 'post-1');
      expect(stats.contentType, 'post');
      expect(stats.viewsCount, 100);
      expect(stats.likesCount, 25);
      expect(stats.commentsCount, 10);
      expect(stats.sharesCount, 5);
      expect(stats.engagementRate, 0.4);
    });

    test('fromJson handles null/missing fields with defaults', () {
      final json = {
        'content_id': 'post-2',
        'content_type': 'story',
      };

      final stats = ContentStats.fromJson(json);

      expect(stats.viewsCount, 0);
      expect(stats.likesCount, 0);
      expect(stats.commentsCount, 0);
      expect(stats.sharesCount, 0);
      expect(stats.engagementRate, 0.0);
    });

    test('totalEngagement sums likes + comments + shares', () {
      final stats = ContentStats(
        contentId: 'c1',
        contentType: 'post',
        viewsCount: 200,
        likesCount: 30,
        commentsCount: 15,
        sharesCount: 5,
        engagementRate: 0.25,
      );

      expect(stats.totalEngagement, 50); // 30 + 15 + 5
    });

    test('totalEngagement is zero when all interaction counts are zero', () {
      final stats = ContentStats(
        contentId: 'c2',
        contentType: 'post',
        viewsCount: 100,
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        engagementRate: 0.0,
      );

      expect(stats.totalEngagement, 0);
    });
  });

  group('EngagementData', () {
    test('fromJson creates instance with all fields', () {
      final json = {
        'date': '2026-02-15T00:00:00.000Z',
        'posts': 3,
        'likes': 12,
        'comments': 5,
      };

      final data = EngagementData.fromJson(json);

      expect(data.date, DateTime.parse('2026-02-15T00:00:00.000Z'));
      expect(data.posts, 3);
      expect(data.likes, 12);
      expect(data.comments, 5);
    });

    test('fromJson handles null fields with defaults', () {
      final json = {
        'date': '2026-01-01T00:00:00.000Z',
      };

      final data = EngagementData.fromJson(json);

      expect(data.posts, 0);
      expect(data.likes, 0);
      expect(data.comments, 0);
    });

    test('totalEngagement sums posts + likes + comments', () {
      final data = EngagementData(
        date: DateTime(2026, 2, 15),
        posts: 2,
        likes: 8,
        comments: 4,
      );

      expect(data.totalEngagement, 14); // 2 + 8 + 4
    });
  });

  group('UserStats', () {
    test('fromJson creates instance with all fields', () {
      final json = {
        'user_id': 'user-1',
        'posts_count': 42,
        'followers_count': 150,
        'following_count': 80,
        'likes_received': 500,
        'comments_received': 120,
        'engagement_score': 7.5,
        'last_active': '2026-02-15T10:30:00.000Z',
        'updated_at': '2026-02-15T12:00:00.000Z',
      };

      final stats = UserStats.fromJson(json);

      expect(stats.userId, 'user-1');
      expect(stats.postsCount, 42);
      expect(stats.followersCount, 150);
      expect(stats.followingCount, 80);
      expect(stats.likesReceived, 500);
      expect(stats.commentsReceived, 120);
      expect(stats.engagementScore, 7.5);
      expect(stats.lastActive, DateTime.parse('2026-02-15T10:30:00.000Z'));
      expect(stats.updatedAt, DateTime.parse('2026-02-15T12:00:00.000Z'));
    });

    test('fromJson handles null/missing fields with defaults', () {
      final json = {
        'user_id': 'user-2',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };

      final stats = UserStats.fromJson(json);

      expect(stats.postsCount, 0);
      expect(stats.followersCount, 0);
      expect(stats.followingCount, 0);
      expect(stats.likesReceived, 0);
      expect(stats.commentsReceived, 0);
      expect(stats.engagementScore, 0.0);
      expect(stats.lastActive, isNull);
    });
  });
}
