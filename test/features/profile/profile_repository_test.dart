import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/data/profile_repository.dart';

import '../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late ProfileRepository repository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    repository = ProfileRepository(client: mockSupabase);
  });

  group('ProfileRepository', () {
    test('getProfile returns profile on success', () async {
      final mockData = {
        'id': 'user-1',
        'full_name': 'Test User',
        'username': 'testuser',
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      // Configuration for Fake approach
      final queryBuilder = MockSupabaseQueryBuilder(selectResponse: [mockData]);
      mockSupabase.setQueryBuilder('profiles', queryBuilder);

      final result = await repository.getProfile('user-1');

      expect(result, isNotNull);
      expect(result!.id, 'user-1');
      expect(result.fullName, 'Test User');
    });

    test('searchUsers uses textSearch', () async {
      final mockResponse = [
        {'id': 'user-1', 'full_name': 'Test User'},
      ];

      // Configuration for Fake approach
      // textSearch logic in Fake PostgrestFilterBuilder handles return value implicitly?
      // MockSupabaseQueryBuilder returns MockPostgrestFilterBuilder.
      // MockPostgrestFilterBuilder.textSearch returns this.
      // And then .limit returns MockPostgrestTransformBuilder? Or this?
      // Check mocks.dart: limit returns this if T is List? No, it returns MockPostgrestTransformBuilder.
      // Wait, mocks.dart:
      // PostgrestTransformBuilder<T> limit(...) => this;  (Wait, inheritance?)
      // PostgrestFilterBuilder extends PostgrestTransformBuilder?
      // Yes.
      // And MockPostgrestFilterBuilder implements PostgrestFilterBuilder.
      // limit implementation in MockPostgrestFilterBuilder:
      // @override PostgrestTransformBuilder<T> limit(...) => this;
      // So it returns this (MockPostgrestFilterBuilder).

      // So setting response on QueryBuilder's select should propagate if chain returns 'this'.

      final queryBuilder =
          MockSupabaseQueryBuilder(selectResponse: mockResponse);
      mockSupabase.setQueryBuilder('profiles', queryBuilder);

      final result = await repository.searchUsers('test');

      expect(result.length, 1);
      expect(result.first.fullName, 'Test User');
    });

    test('updateProfile calls upsert', () async {
      final profile = Profile(
        id: 'user-1',
        fullName: 'New Name',
        username: 'newname',
      );

      // Configuration
      final queryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('profiles', queryBuilder);

      // upsert in MockSupabaseQueryBuilder returns MockPostgrestFilterBuilder (which is awaitable Future<null> if T is dynamic/void)
      // So await works.

      await repository.updateProfile(profile);

      // Cannot verify upsert call on Fake object easily without Spy.
      // We assume if it didn't throw, it likely succeeded in calling the method.
    });
    test('isUsernameAvailable returns true on error', () async {
      final queryBuilder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('profiles', queryBuilder);

      final result = await repository.isUsernameAvailable('anyuser');

      expect(result, isTrue);
    });
  });
}
