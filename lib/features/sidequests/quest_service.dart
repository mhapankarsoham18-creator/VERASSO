import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'quest_data.dart';
import 'title_system.dart';

class QuestService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Gets 10 deterministic daily quests for a user based on their ID and the date.
  List<Quest> getDailyQuests(String userId) {
    final now = DateTime.now();
    // Seed using date string + userId to ensure same order all day but different per user
    final seedString = '${now.year}-${now.month}-${now.day}_$userId';
    final random = Random(seedString.hashCode);
    
    // Copy the pool so we can shuffle safely
    final pool = List<Quest>.from(questPool)..shuffle(random);
    
    final List<Quest> selected = [];
    final Map<QuestCategory, int> categoryCount = {};

    for (var quest in pool) {
      if (selected.length >= 10) break;
      
      final currentCategoryCount = categoryCount[quest.category] ?? 0;
      // Max 2 quests per category per day to ensure diversity
      if (currentCategoryCount < 2) {
        selected.add(quest);
        categoryCount[quest.category] = currentCategoryCount + 1;
      }
    }

    // fallback if somehow filtered < 10 (unlikely with 140+ quests)
    if (selected.length < 10) {
      for (var quest in pool) {
        if (selected.length >= 10) break;
        if (!selected.contains(quest)) selected.add(quest);
      }
    }

    return selected;
  }

  /// Check if a specific quest has been completed today by the user.
  Future<bool> isQuestCompletedToday(String profileId, String questId) async {
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    
    // Check if there is an entry in quest_completions for today
    final response = await _supabase
        .from('quest_completions')
        .select('id')
        .eq('profile_id', profileId)
        .eq('quest_id', questId)
        .gte('completed_at', '${today}T00:00:00Z')
        .maybeSingle();

    return response != null;
  }
  
  /// Get all completed quest IDs for today to render the UI checkboxes
  Future<Set<String>> getTodayCompletedQuestIds(String profileId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _supabase
        .from('quest_completions')
        .select('quest_id')
        .eq('profile_id', profileId)
        .gte('completed_at', '${today}T00:00:00Z');
        
    return (response as List).map((row) => row['quest_id'] as String).toSet();
  }

  /// Complete a quest: Prompt for photo (camera or gallery), upload, and register completion.
  /// Returns [true, new_xp] if leveling up occurred, [false, new_xp] otherwise, or null if failed/cancelled.
  Future<List<dynamic>?> completeQuest(String profileId, Quest quest, ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 70, 
        maxWidth: 1080,
      );

      if (photo == null) return null; // User cancelled

      // 1. Upload photo to quest-photos bucket
      final fileExtension = '.${photo.path.split('.').last}';
      final fileName = '${profileId}_${quest.id}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final fileData = File(photo.path).readAsBytesSync();
      
      await _supabase.storage.from('quest-photos').uploadBinary(
        fileName,
        fileData,
        fileOptions: FileOptions(contentType: 'image/${fileExtension.replaceAll(".", "")}'),
      );

      final photoUrl = _supabase.storage.from('quest-photos').getPublicUrl(fileName);

      // 2. Fetch current XP before update for level-up check
      final profileReq = await _supabase
          .from('profiles')
          .select('sidequest_xp')
          .eq('id', profileId)
          .single();
      final oldXp = profileReq['sidequest_xp'] as int? ?? 0;

      // 3. Check if already completed today (resubmitting proof)
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existingCompletion = await _supabase
          .from('quest_completions')
          .select('id')
          .eq('profile_id', profileId)
          .eq('quest_id', quest.id)
          .gte('completed_at', '${today}T00:00:00Z')
          .maybeSingle();

      if (existingCompletion != null) {
        // Simply update the photo URL
        await _supabase.from('quest_completions').update({
          'photo_url': photoUrl,
        }).eq('id', existingCompletion['id']);
        
        // Return without leveling up or adding duplicate XP
        return [false, oldXp];
      }

      // 4. Register new completion in 'quest_completions'
      await _supabase.from('quest_completions').insert({
        'profile_id': profileId,
        'quest_id': quest.id,
        'photo_url': photoUrl,
        'xp_awarded': quest.xp,
      });

      // 5. Call RPC to update XP securely
      await _supabase.rpc('add_sidequest_xp', params: {
        'p_profile_id': profileId,
        'p_xp': quest.xp,
      });

      // 6. Post to the public feed
      await _supabase.from('posts').insert({
        'author_id': profileId,
        'type': 'sidequest',
        'content': '${quest.emoji} Completed Sidequest: ${quest.title} (+${quest.xp} XP)',
        'media_url': photoUrl,
      });

      // 7. Check if leveled up
      final newXp = oldXp + quest.xp;
      final didLevelUp = TitleSystem.didJustLevelUp(oldXp, newXp);

      // If leveled up, update the profile title
      if (didLevelUp) {
        final newTier = TitleSystem.getCurrentTier(newXp);
        await _supabase.from('profiles').update({
          'sidequest_title': newTier.title,
        }).eq('id', profileId);
      }

      return [didLevelUp, newXp];
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      debugPrint('Sidequest Error: $e');
      return null;
    }
  }
}
