import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/features/gamification/services/guild_service.dart';

import '../../../mocks.dart';

void main() {
  late GuildService guildService;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    guildService = GuildService(mockSupabase);
  });

  group('GuildService', () {
    test('getGuild returns guild model on success', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder(
        selectResponse: {
          'id': 'guild-1',
          'name': 'Alpha',
          'leader_id': 'user-1',
          'guild_xp': 1000,
          'member_count': 5,
          'max_members': 20,
        },
      );
      mockSupabase.setQueryBuilder('guilds', mockQueryBuilder);

      final guild = await guildService.getGuild('guild-1');
      expect(guild.name, 'Alpha');
      expect(guild.leaderId, 'user-1');
    });

    test('createGuildStudyRoom inserts record', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('study_room_sessions', mockQueryBuilder);

      await guildService.createGuildStudyRoom('guild-1', 'Study Math');

      expect(mockSupabase.lastInsertTable, 'study_room_sessions');
    });

    test('updateMemberRole throws error if not leader', () async {
      final mockAuth = MockGoTrueClient();
      final mockUser = TestSupabaseUser(id: 'user-not-leader');
      mockAuth.setCurrentUser(mockUser);
      mockSupabase.setAuth(mockAuth);

      final mockQueryBuilder = MockSupabaseQueryBuilder(
        selectResponse: {
          'id': 'guild-1',
          'name': 'Alpha',
          'leader_id': 'user-actual-leader',
          'guild_xp': 0,
          'member_count': 1,
          'max_members': 20,
        },
      );
      mockSupabase.setQueryBuilder('guilds', mockQueryBuilder);

      expect(
          () => guildService.updateMemberRole('guild-1', 'user-2', 'officer'),
          throwsA(isA<DatabaseException>()));
    });
  });
}
