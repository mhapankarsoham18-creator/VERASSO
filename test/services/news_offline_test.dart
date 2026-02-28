// ignore_for_file: must_be_immutable
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/features/news/data/mesh_news_service.dart';
import 'package:verasso/features/news/data/news_repository.dart';
import 'package:verasso/features/news/domain/news_model.dart';

// --- TEST ---

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockOfflineStorageService mockStorage;
  late MockMeshNewsNotifier mockMeshNewsNotifier;
  late ProviderContainer container;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockSupabase = MockSupabaseClient(auth: mockAuth);
    mockStorage = MockOfflineStorageService();
    mockMeshNewsNotifier = MockMeshNewsNotifier(mockStorage);

    // Setup ProviderContainer
    container = ProviderContainer(
      overrides: [
        offlineStorageServiceProvider.overrideWithValue(mockStorage),
        meshNewsServiceProvider.overrideWith((ref) => mockMeshNewsNotifier),
        newsRepositoryProvider
            .overrideWith((ref) => NewsRepository(mockSupabase, ref)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('NewsRepository Offline Caching', () {
    final articleJson = {
      'id': '1',
      'title': 'Test Article',
      'content': 'Content',
      'summary': 'Summary',
      'author_id': 'author1',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'image_url': 'http://image.com',
      'is_featured': true,
      'is_published': true,
      'subject': 'Tech',
      'audience_type': 'General',
      'profiles': {'full_name': 'Author', 'avatar_url': 'http://avatar.com'}
    };
    final articlesList = [articleJson];

    test('getArticles caches data when fetch is successful', () async {
      // Arrange
      final mockQueryBuilder = SuccessMockSupabaseQueryBuilder(articlesList);
      mockSupabase.setQueryBuilder('articles', mockQueryBuilder);

      final repository = container.read(newsRepositoryProvider);

      // Act
      await repository.getArticles(featuredOnly: true);

      // Assert
      verify(mockStorage.cacheData('featured_news_cache', any)).called(1);
    });

    test('getArticles fetches from cache when Supabase fails', () async {
      // Arrange
      mockSupabase.setQueryBuilder('articles', ErrorMockSupabaseQueryBuilder());
      when(mockStorage.getCachedData('featured_news_cache'))
          .thenReturn(articlesList);

      final repository = container.read(newsRepositoryProvider);

      // Act
      final result = await repository.getArticles(featuredOnly: true);

      // Assert
      expect(result.length, 1);
      expect(result.first.id, '1');
      verify(mockStorage.getCachedData('featured_news_cache')).called(1);
    });

    test('getArticles returns empty if Supabase fails and Cache is empty',
        () async {
      // Arrange
      mockSupabase.setQueryBuilder('articles', ErrorMockSupabaseQueryBuilder());
      when(mockStorage.getCachedData('featured_news_cache')).thenReturn(null);

      final repository = container.read(newsRepositoryProvider);

      // Act
      final result = await repository.getArticles(featuredOnly: true);

      // Assert
      expect(result, isEmpty);
    });
  });
}

class ErrorMockSupabaseQueryBuilder extends MockSupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    throw const DatabaseException('Offline');
  }
}

class MockBluetoothMeshService extends Mock implements BluetoothMeshService {
  @override
  Stream<MeshPacket> get meshStream => const Stream.empty();
}

class MockGoTrueClient extends Mock implements GoTrueClient {
  @override
  User? get currentUser => User(
      id: 'test-user',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '');
}

class MockMeshNewsNotifier extends MeshNewsService {
  MockMeshNewsNotifier(OfflineStorageService storage)
      : super(MockBluetoothMeshService(), storage);

  @override
  Future<void> broadcastArticle(NewsArticle article) async {}
}

class MockOfflineStorageService extends Mock implements OfflineStorageService {
  @override
  Future<void> cacheData(String key, dynamic value) async => super.noSuchMethod(
        Invocation.method(#cacheData, [key, value]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );

  @override
  dynamic getCachedData(String key, {Duration? expiration}) =>
      super.noSuchMethod(
        Invocation.method(#getCachedData, [key], {#expiration: expiration}),
        returnValue: null,
      );
}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {
  final T _response;
  MockPostgrestFilterBuilder(this._response);

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> order(String column,
          {bool ascending = true,
          bool nullsFirst = false,
          String? referencedTable}) =>
      this;

  @override
  PostgrestFilterBuilder<T> range(int from, int to,
          {String? referencedTable}) =>
      this;

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(_response).then(onValue, onError: onError);
  }
}

// --- MOCKS ---

class MockSupabaseClient extends Mock implements SupabaseClient {
  final GoTrueClient _auth;
  final Map<String, SupabaseQueryBuilder> _overrides = {};

  MockSupabaseClient({GoTrueClient? auth}) : _auth = auth ?? MockGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) =>
      _overrides[table] ?? MockSupabaseQueryBuilder();

  void setQueryBuilder(String table, SupabaseQueryBuilder builder) {
    _overrides[table] = builder;
  }
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> _selectResponse;

  MockSupabaseQueryBuilder({List<Map<String, dynamic>>? selectResponse})
      : _selectResponse = selectResponse ?? [];

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    return MockPostgrestFilterBuilder(_selectResponse);
  }
}

class SuccessMockSupabaseQueryBuilder extends MockSupabaseQueryBuilder {
  SuccessMockSupabaseQueryBuilder(List<Map<String, dynamic>> data)
      : super(selectResponse: data);
}
