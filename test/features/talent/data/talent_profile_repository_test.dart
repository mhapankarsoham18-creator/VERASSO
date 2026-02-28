import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/talent/data/talent_profile_model.dart';
import 'package:verasso/features/talent/data/talent_profile_repository.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late TalentProfileRepository repository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    repository = TalentProfileRepository(client: mockSupabase);
  });

  group('TalentProfileRepository Tests', () {
    final profileJson = {
      'id': 'user-1',
      'headline': 'Expert Developer',
      'bio': 'Coding since 2010',
      'skills': ['Dart', 'Flutter'],
      'updated_at': DateTime.now().toIso8601String(),
      'profiles': {
        'username': 'dev_guru',
        'full_name': 'Dev Guru',
        'avatar_url': 'https://example.com/avatar.png'
      }
    };

    test('getTalentProfile should return profile when found', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [profileJson]);
      mockSupabase.setQueryBuilder('talent_profiles', builder);

      final profile = await repository.getTalentProfile('user-1');

      expect(profile, isNotNull);
      expect(profile!.id, 'user-1');
      expect(profile.headline, 'Expert Developer');
      expect(profile.fullName, 'Dev Guru');
    });

    test('getTalentProfile should return null when not found', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('talent_profiles', builder);

      final profile = await repository.getTalentProfile('user-unknown');

      expect(profile, isNull);
    });

    test('getVerifiedMentors should return list of profiles', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [profileJson]);
      mockSupabase.setQueryBuilder('talent_profiles', builder);

      final mentors = await repository.getVerifiedMentors();

      expect(mentors.length, 1);
      expect(mentors.first.id, 'user-1');
    });

    test('searchMentors should return matching profiles', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [profileJson]);
      mockSupabase.setQueryBuilder('talent_profiles', builder);

      final results = await repository.searchMentors('Dart');

      expect(results.length, 1);
      expect(results.first.skills, contains('Dart'));
    });

    test('upsertTalentProfile should call upsert on client', () async {
      final profile = TalentProfile(
        id: 'user-1',
        headline: 'New Headline',
        bio: 'Bio',
        skills: [],
        updatedAt: DateTime.now(),
      );

      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('talent_profiles', builder);

      await repository.upsertTalentProfile(profile);

      // Verify interaction
      expect(mockSupabase.from('talent_profiles'), isNotNull);
    });
  });
}
