import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/search/data/search_service.dart';
import 'package:verasso/features/search/models/search_results.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late SearchService service;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    service = SearchService(client: mockSupabase);
  });

  group('SearchService Tests', () {
    test('searchUsers should return user results', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'u1',
          'full_name': 'Alice Smith',
          'avatar_url': null,
          'bio': 'Student',
        },
      ]);
      mockSupabase.setQueryBuilder('profiles', builder);

      final result = await service.searchUsers('Alice');

      expect(result.length, 1);
      expect(result.first.fullName, 'Alice Smith');
      expect(result.first.bio, 'Student');
    });

    test('searchUsers should return empty for blank query', () async {
      final result = await service.searchUsers('   ');

      expect(result, isEmpty);
    });

    test('searchGroups should return group results', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'g1',
          'name': 'Physics Club',
          'description': 'Advanced physics',
          'avatar_url': null,
          'member_count': 42,
        },
      ]);
      mockSupabase.setQueryBuilder('groups', builder);

      final result = await service.searchGroups('Physics');

      expect(result.length, 1);
      expect(result.first.name, 'Physics Club');
      expect(result.first.memberCount, 42);
    });

    test('searchGroups should return empty for blank query', () async {
      final result = await service.searchGroups('');

      expect(result, isEmpty);
    });
  });

  group('Search Model Tests', () {
    test('UserSearchResult.fromJson handles missing full_name', () {
      final result = UserSearchResult.fromJson({
        'id': 'u1',
      });

      expect(result.fullName, 'Unknown User');
    });

    test('GroupSearchResult.fromJson handles defaults', () {
      final result = GroupSearchResult.fromJson({
        'id': 'g1',
      });

      expect(result.name, 'Unnamed Group');
      expect(result.memberCount, 0);
    });

    test('PostSearchResult.fromJson handles missing profile', () {
      final result = PostSearchResult.fromJson({
        'id': 'p1',
        'user_id': 'u1',
        'content': 'Test',
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(result.authorName, isNull);
      expect(result.content, 'Test');
    });

    test('SearchResults isEmpty and totalCount', () {
      final empty = SearchResults(users: [], posts: [], groups: []);
      expect(empty.isEmpty, true);
      expect(empty.totalCount, 0);

      final nonEmpty = SearchResults(
        users: [
          UserSearchResult(id: '1', fullName: 'A'),
        ],
        posts: [],
        groups: [],
      );
      expect(nonEmpty.isEmpty, false);
      expect(nonEmpty.totalCount, 1);
    });
  });
}
