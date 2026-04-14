import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../quest_data.dart';
import '../quest_service.dart';
import '../title_system.dart';
import 'level_up_screen.dart';

/// The Zelda-style Quest Board hub
class QuestBoardScreen extends StatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  State<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends State<QuestBoardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final QuestService _questService = QuestService();
  
  String _profileId = '';
  int _currentXp = 0;
  String _currentTitle = 'Wanderer';
  int _currentStreak = 0;
  
  List<Quest> _dailyQuests = [];
  Set<String> _completedQuestIds = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    // Always provide quests even if completely offline by using firebase UID as deterministic seed
    _profileId = fbUser.uid;
    _dailyQuests = _questService.getDailyQuests(_profileId);

    final box = Hive.box('sidequests_cache');
    final cachedProfile = box.get('profile_${fbUser.uid}');
    if (cachedProfile != null) {
      _profileId = cachedProfile['id'] as String;
      _currentXp = cachedProfile['sidequest_xp'] as int? ?? 0;
      _currentTitle = cachedProfile['sidequest_title'] as String? ?? 'Wanderer';
      _currentStreak = cachedProfile['sidequest_streak'] as int? ?? 0;
      
      _dailyQuests = _questService.getDailyQuests(_profileId);
      
      final cachedCompletions = box.get('completions_$_profileId');
      if (cachedCompletions != null) {
        _completedQuestIds = Set<String>.from(cachedCompletions);
      }
      
      // Load UI instantly from cache
      if (mounted) setState(() => _isLoading = false);
    }

    try {
      // Fetch Profile using Firebase UID
      final profileReq = await _supabase
          .from('profiles')
          .select('id, sidequest_xp, sidequest_title, sidequest_streak')
          .eq('firebase_uid', fbUser.uid)
          .maybeSingle();
          
      if (profileReq != null) {
        box.put('profile_${fbUser.uid}', profileReq);
        _profileId = profileReq['id'] as String;
        _currentXp = profileReq['sidequest_xp'] as int? ?? 0;
        _currentTitle = profileReq['sidequest_title'] as String? ?? 'Wanderer';
        _currentStreak = profileReq['sidequest_streak'] as int? ?? 0;
        
        _dailyQuests = _questService.getDailyQuests(_profileId);
        
        _completedQuestIds = await _questService.getTodayCompletedQuestIds(_profileId);
        box.put('completions_$_profileId', _completedQuestIds.toList());
      }
    } catch (e) {
      debugPrint('Sidequests offline sync failed: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showImageSourcePicker(Quest quest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _completeQuest(quest, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _completeQuest(quest, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _completeQuest(Quest quest, ImageSource source) async {
    // Show loading dialog
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    final result = await _questService.completeQuest(_profileId, quest, source);
    
    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (result == null) {
      // User cancelled or error
      return;
    }

    final bool didLevelUp = result[0] as bool;
    final int newXp = result[1] as int;
    
    final oldTier = TitleSystem.getCurrentTier(_currentXp);
    final newTier = TitleSystem.getCurrentTier(newXp);

    setState(() {
      _currentXp = newXp;
      _currentTitle = newTier.title;
      _completedQuestIds.add(quest.id);
      
      // Speculatively update streak if it was the first today
      if (_completedQuestIds.length == 1 && _currentStreak == 0) {
        _currentStreak = 1; 
      }
    });

    if (didLevelUp && mounted) {
      await LevelUpScreen.show(context, oldTier, newTier);
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D3B),
          title: Text('${quest.emoji} Quest Complete!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('You earned +${quest.xp} XP for verifying this quest.\n\nGreat job!', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome', style: TextStyle(color: Colors.amber)),
            )
          ],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E28),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tier = TitleSystem.getCurrentTier(_currentXp);
    final nextTier = TitleSystem.getNextTier(_currentXp);
    final progress = TitleSystem.getProgressToNextTier(_currentXp);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E28), 
      appBar: AppBar(
        title: const Text('⚔️ Sidequests', style: TextStyle(fontFamily: 'Pixel', letterSpacing: 2)),
        backgroundColor: const Color(0xFF2E2E3A),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Headboard
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tier.emoji} ${_currentTitle.toUpperCase()}', 
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        )
                      ),
                      Row(
                        children: [
                          const Text('🔥 ', style: TextStyle(fontSize: 18)),
                          Text('$_currentStreak', style: const TextStyle(fontSize: 18, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black45,
                    color: Colors.amber,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextTier != null 
                        ? '$_currentXp / ${nextTier.xpThreshold} XP'
                        : 'MAX LEVEL',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quests List
            ..._dailyQuests.map((q) => _buildQuestScroll(q)),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestScroll(Quest quest) {
    final isCompleted = _completedQuestIds.contains(quest.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      color: isCompleted ? const Color(0xFFD6C8A6) : const Color(0xFFF4E4C1), // Parchment colors
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Text(quest.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title, 
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                       isCompleted ? 'COMPLETED • +${quest.xp} XP' : '+${quest.xp} XP • Tap to open', 
                       style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.green.shade800 : Colors.brown, fontSize: 12)
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Removing custom trailing so the default dropdown arrow appears, signaling it's clickable
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    quest.description,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera, size: 16, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Proof: ${quest.photoPrompt}', style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? Colors.black45 : Colors.brown.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showImageSourcePicker(quest),
                    child: Text(isCompleted ? 'UPDATE PROOF PHOTO' : 'SUBMIT PROOF', style: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
