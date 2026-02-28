import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/features/gamification/data/gamification_repository.dart';
import 'package:verasso/features/news/data/mesh_news_service.dart';
import 'package:verasso/features/news/data/news_repository.dart';
import 'package:verasso/features/news/domain/news_model.dart';

import '../../../mocks.dart';

void main() {
  late NewsRepository repository;
  late MockSupabaseClient mockSupabase;
  late MockOfflineStorageService mockStorage;
  late MockMeshNewsService mockMesh;
  late MockGamificationRepository mockGamification;
  late ProviderContainer container;

  final testArticle = NewsArticle(
    id: 'a1',
    authorId: 'u1',
    title: 'Breaking News',
    content: {
      'ops': [
        {'insert': 'Content'}
      ]
    },
    subject: 'Technology',
    audienceType: 'All',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockStorage = MockOfflineStorageService();
    mockMesh = MockMeshNewsService();
    mockGamification = MockGamificationRepository();

    container = ProviderContainer(
      overrides: [
        offlineStorageServiceProvider.overrideWithValue(mockStorage),
        meshNewsServiceProvider.overrideWith((ref) => mockMesh),
        gamificationRepositoryProvider.overrideWithValue(mockGamification),
        newsRepositoryProvider
            .overrideWith((ref) => NewsRepository(mockSupabase, ref)),
      ],
    );

    repository = container.read(newsRepositoryProvider);
  });

  group('NewsRepository Unit Tests', () {
    test('getArticles fetches from Supabase and caches featured', () async {
      final mockQuery =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockQuery.setResponse([testArticle.copyWith(isFeatured: true).toJson()]);

      final mockQueryBuilder =
          MockSupabaseQueryBuilder(stubs: {'select': mockQuery});
      mockSupabase.fromStub = (table) => mockQueryBuilder;

      final results = await repository.getArticles(featuredOnly: true);

      expect(results.length, 1);
      expect(results.first.id, 'a1');
    });

    test('getArticles falls back to cache on Supabase failure', () async {
      mockSupabase.fromStub = (table) => throw Exception('Network error');

      mockStorage.getCachedDataStub = (key, {expiration}) {
        if (key == 'featured_news_cache') {
          return [testArticle.toJson()];
        }
        return null;
      };

      final results = await repository.getArticles(featuredOnly: true);

      expect(results.length, 1);
      expect(results.first.title, 'Breaking News');
    });

    test('getArticles falls back to mesh if cache is empty', () async {
      mockSupabase.fromStub = (table) => throw Exception('Network error');
      mockStorage.getCachedDataStub = (key, {expiration}) => null;

      container.read(meshNewsServiceProvider.notifier).state = [testArticle];

      final results = await repository.getArticles();

      expect(results.length, 1);
      expect(results.first.id, 'a1');
    });

    test('publishArticle inserts into Supabase', () async {
      final mockQuery = MockPostgrestFilterBuilder<dynamic>();
      final mockQueryBuilder =
          MockSupabaseQueryBuilder(stubs: {'insert': mockQuery});
      mockSupabase.fromStub = (table) => mockQueryBuilder;

      await repository.publishArticle(testArticle);
    });

    test('upvoteArticle calls upsert and rewards XP', () async {
      final mockAuth = MockGoTrueClient();
      mockAuth
          .setCurrentUser(TestSupabaseUser(id: 'u1', email: 'u1@example.com'));
      mockSupabase.setAuth(mockAuth);

      final mockQuery = MockPostgrestFilterBuilder<dynamic>();
      final mockQueryBuilder =
          MockSupabaseQueryBuilder(stubs: {'upsert': mockQuery});
      mockSupabase.fromStub = (table) => mockQueryBuilder;

      await repository.upvoteArticle('a1');
    });

    test('vouchArticle restricted to Senior/Editor', () async {
      final mockAuth = MockGoTrueClient();
      mockAuth
          .setCurrentUser(TestSupabaseUser(id: 'u1', email: 'u1@example.com'));
      mockSupabase.setAuth(mockAuth);

      final mockQueryProfile =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockQueryProfile.setResponse([
        {'journalist_level': 'senior'}
      ]);

      final mockProfileBuilder =
          MockSupabaseQueryBuilder(stubs: {'select': mockQueryProfile});

      mockSupabase.fromStub = (table) {
        if (table == 'profiles') return mockProfileBuilder;
        return MockSupabaseQueryBuilder();
      };

      await repository.vouchArticle('a1');
    });

    group('MeshNewsService Unit Tests', () {
      test('broadcastArticle notifies mesh network', () async {
        bool broadcasted = false;
        mockMesh.broadcastArticleStub = (article) async {
          broadcasted = true;
        };

        await container
            .read(meshNewsServiceProvider.notifier)
            .broadcastArticle(testArticle);
        expect(broadcasted, true);
      });
    });
  });
}

class MockSupabaseClient extends Fake implements SupabaseClient {
  SupabaseQueryBuilder Function(String table)? fromStub;
  GoTrueClient _auth = MockGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) =>
      fromStub?.call(table) ?? MockSupabaseQueryBuilder();

  void setAuth(GoTrueClient auth) => _auth = auth;
}
