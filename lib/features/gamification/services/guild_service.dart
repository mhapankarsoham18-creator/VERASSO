import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [GuildService].
final guildServiceProvider = Provider<GuildService>((ref) {
  return GuildService(Supabase.instance.client);
});

/// Model for a guild.
class Guild {
  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Guild description.
  final String? description;

  /// URL to guild emblem.
  final String? emblemUrl;

  /// ID of the guild leader.
  final String leaderId;

  /// Total guild XP.
  final int guildXP;

  /// Current member count.
  final int memberCount;

  /// Maximum members.
  final int maxMembers;

  /// Creates a [Guild].
  const Guild({
    required this.id,
    required this.name,
    this.description,
    this.emblemUrl,
    required this.leaderId,
    required this.guildXP,
    required this.memberCount,
    required this.maxMembers,
  });

  /// Creates from JSON.
  factory Guild.fromJson(Map<String, dynamic> json) => Guild(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'],
        emblemUrl: json['emblem_url'],
        leaderId: json['leader_id'],
        guildXP: json['guild_xp'] ?? 0,
        memberCount: json['member_count'] ?? 1,
        maxMembers: json['max_members'] ?? 20,
      );

  /// Whether the guild has room for more members.
  bool get hasSpace => memberCount < maxMembers;
}

/// Model for a guild member.
class GuildMember {
  /// Guild ID.
  final String guildId;

  /// User ID.
  final String userId;

  /// Role: leader, officer, moderator, member.
  final String role;

  /// Total XP contributed to the guild.
  final int xpContributed;

  /// When the member joined.
  final DateTime joinedAt;

  /// Creates a [GuildMember].
  const GuildMember({
    required this.guildId,
    required this.userId,
    required this.role,
    required this.xpContributed,
    required this.joinedAt,
  });

  /// Creates from JSON.
  factory GuildMember.fromJson(Map<String, dynamic> json) => GuildMember(
        guildId: json['guild_id'],
        userId: json['user_id'],
        role: json['role'] ?? 'member',
        xpContributed: json['xp_contributed'] ?? 0,
        joinedAt: DateTime.parse(json['joined_at']),
      );

  /// Whether this member has any management permissions.
  bool get canModerate => isLeader || isOfficer || isModerator;

  /// Whether this member is the leader.
  bool get isLeader => role == 'leader';

  /// Whether this member is a moderator.
  bool get isModerator => role == 'moderator';

  /// Whether this member is an officer.
  bool get isOfficer => role == 'officer';
}

/// Service for managing guilds.
class GuildService {
  final SupabaseClient _supabase;

  /// Creates a [GuildService].
  GuildService(this._supabase);

  /// Creates a new guild. The current user becomes the leader.
  Future<Guild> createGuild({
    required String name,
    String? description,
    String? emblemUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Check if user is already in a guild
      final existing = await getMyGuild();
      if (existing != null) {
        throw const DatabaseException(
            'You are already in a guild. Leave first.');
      }

      final response = await _supabase
          .from('guilds')
          .insert({
            'name': name,
            'description': description,
            'emblem_url': emblemUrl,
            'leader_id': userId,
          })
          .select()
          .single();

      final guild = Guild.fromJson(response);

      // Add leader as first member
      await _supabase.from('guild_members').insert({
        'guild_id': guild.id,
        'user_id': userId,
        'role': 'leader',
      });

      return guild;
    } catch (e) {
      AppLogger.error('Failed to create guild', error: e);
      rethrow;
    }
  }

  /// Creates a private study room session for the guild.
  Future<void> createGuildStudyRoom(String guildId, String title) async {
    try {
      await _supabase.from('study_room_sessions').insert({
        'group_id': guildId, // Guild ID is used as the group mapping
        'title': title,
        'is_live': true,
      });
    } catch (e) {
      throw DatabaseException('Failed to create guild study room: $e', null, e);
    }
  }

  /// Demotes a member to standard member (leader only).
  Future<void> demoteMember(String guildId, String userId) async {
    await updateMemberRole(guildId, userId, 'member');
  }

  /// Gets a guild by ID.
  Future<Guild> getGuild(String guildId) async {
    try {
      final response =
          await _supabase.from('guilds').select().eq('id', guildId).single();
      return Guild.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to get guild: $e', null, e);
    }
  }

  /// Stubs for guild announcements/forums functionality.
  Future<List<Map<String, dynamic>>> getGuildAnnouncements(
      String guildId) async {
    // Current placeholder, would ideally link to a news/broadcast table
    return [];
  }

  /// Gets the guild leaderboard (top guilds by XP).
  Future<List<Guild>> getGuildLeaderboard({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('guilds')
          .select()
          .eq('is_active', true)
          .order('guild_xp', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Guild.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get guild leaderboard: $e', null, e);
    }
  }

  /// Gets all members of a guild.
  Future<List<GuildMember>> getGuildMembers(String guildId) async {
    try {
      final response = await _supabase
          .from('guild_members')
          .select()
          .eq('guild_id', guildId)
          .order('xp_contributed', ascending: false);

      return (response as List)
          .map((json) => GuildMember.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get guild members: $e', null, e);
    }
  }

  /// Retrieves active study room sessions for the guild.
  Future<List<Map<String, dynamic>>> getGuildStudyRooms(String guildId) async {
    try {
      final response = await _supabase
          .from('study_room_sessions')
          .select()
          .eq('group_id', guildId)
          .eq('is_live', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw DatabaseException('Failed to fetch guild study rooms: $e', null, e);
    }
  }

  /// Gets the current user's guild, or null.
  Future<Guild?> getMyGuild() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final membership = await _supabase
          .from('guild_members')
          .select('guild_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (membership == null) return null;
      return getGuild(membership['guild_id']);
    } catch (e) {
      return null;
    }
  }

  /// Joins an existing guild.
  Future<void> joinGuild(String guildId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Check capacity
      final guild = await getGuild(guildId);
      if (!guild.hasSpace) {
        throw DatabaseException('Guild is full (${guild.maxMembers} members).');
      }

      // Check if already in a guild
      final existing = await getMyGuild();
      if (existing != null) {
        throw const DatabaseException('Leave your current guild first.');
      }

      await _supabase.from('guild_members').insert({
        'guild_id': guildId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e) {
      AppLogger.error('Failed to join guild', error: e);
      rethrow;
    }
  }

  /// Kicks a member (leader/officer/moderator only).
  Future<void> kickMember(String guildId, String userId) async {
    try {
      // Security check could be added here to verify permissions of current user
      await _supabase
          .from('guild_members')
          .delete()
          .eq('guild_id', guildId)
          .eq('user_id', userId);
    } catch (e) {
      AppLogger.error('Failed to kick member', error: e);
      rethrow;
    }
  }

  /// Leaves the current guild.
  Future<void> leaveGuild() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final membership = await _supabase
          .from('guild_members')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (membership == null) return;

      if (membership['role'] == 'leader') {
        // Transfer leadership or disband
        final members = await getGuildMembers(membership['guild_id']);
        if (members.length <= 1) {
          // Last member — disband guild
          await _supabase
              .from('guilds')
              .delete()
              .eq('id', membership['guild_id']);
        } else {
          // Transfer to first officer, then moderator, or first member
          final newLeader = members.firstWhere(
            (m) => m.userId != userId && m.role == 'officer',
            orElse: () => members.firstWhere(
              (m) => m.userId != userId && m.role == 'moderator',
              orElse: () => members.firstWhere((m) => m.userId != userId),
            ),
          );
          await _supabase.from('guilds').update(
              {'leader_id': newLeader.userId}).eq('id', membership['guild_id']);
          await _supabase
              .from('guild_members')
              .update({'role': 'leader'})
              .eq('guild_id', membership['guild_id'])
              .eq('user_id', newLeader.userId);
        }
      }

      await _supabase.from('guild_members').delete().eq('user_id', userId);
    } catch (e) {
      AppLogger.error('Failed to leave guild', error: e);
      rethrow;
    }
  }

  // --- Advanced Collaboration Features ---

  /// Promotes a member to officer (leader only).
  Future<void> promoteMember(String guildId, String userId) async {
    await updateMemberRole(guildId, userId, 'officer');
  }

  /// Searches guilds by name.
  Future<List<Guild>> searchGuilds(String query) async {
    try {
      final response = await _supabase
          .from('guilds')
          .select()
          .eq('is_active', true)
          .ilike('name', '%$query%')
          .limit(20);

      return (response as List).map((json) => Guild.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to search guilds: $e', null, e);
    }
  }

  /// Updates a member's role (leader/officer only).
  Future<void> updateMemberRole(
      String guildId, String userId, String newRole) async {
    try {
      final currentUser = _supabase.auth.currentUser!.id;
      final guild = await getGuild(guildId);
      if (guild.leaderId != currentUser) {
        throw const DatabaseException(
            'Only the guild leader can change roles.');
      }

      await _supabase
          .from('guild_members')
          .update({'role': newRole})
          .eq('guild_id', guildId)
          .eq('user_id', userId);
    } catch (e) {
      AppLogger.error('Failed to update member role', error: e);
      rethrow;
    }
  }
}
