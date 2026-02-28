import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for exporting and backing up user data.
class BackupService {
  final _supabase = Supabase.instance.client;

  /// Exports user data (AR projects, stories, profile) to a JSON file.
  ///
  /// Returns the absolute path to the generated backup file.
  Future<String> exportUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final Map<String, dynamic> exportData = {
        'metadata': {
          'user_id': userId,
          'export_date': DateTime.now().toIso8601String(),
          'app_version': '1.2.0',
        },
        'ar_projects': [],
        'stories': [],
        'profile': {},
      };

      // Fetch AR Projects
      final projectsResponse =
          await _supabase.from('ar_projects').select().eq('user_id', userId);
      exportData['ar_projects'] = projectsResponse;

      // Fetch Stories (Archived too)
      final storiesResponse =
          await _supabase.from('user_stories').select().eq('user_id', userId);
      exportData['stories'] = storiesResponse;

      // Fetch Profile
      final profileResponse =
          await _supabase.from('profiles').select().eq('id', userId).single();
      exportData['profile'] = profileResponse;

      // Convert to JSON
      final jsonString = jsonEncode(exportData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/verasso_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }
}
